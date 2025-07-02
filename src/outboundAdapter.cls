/// crud operations for mongodb 
/// updated for new IRIS 2025 version (embedded python)
Class custom.python.pymongo.outboundAdapter Extends Ens.OutboundAdapter [ ClassType = "", ProcedureBlock, System = 4 ]
{

/// ex: mongodb+srv://&ltdb_user&gt:&ltdb_password&gt@cluster0.y1uie.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0&tlsAllowInvalidCertificates=true
Property MongoUri As %String(MAXLEN = "") [ InitialExpression = "mongodb+srv://&ltdb_user&gt:&ltdb_password&gt@cluster0.y1uie.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0&tlsAllowInvalidCertificates=true" ];

Property Uri As %String(MAXLEN = "");

/// Number of seconds to wait on each connection attempt
Property ConnectTimeout As %Numeric(MINVAL = 0) [ InitialExpression = 5 ];

/// Credentials for &ltdb_user&gt:&ltdb_password&gt string inside MongoUri (opaque)
Property Credentials As %String;

/// pymongo client
Property MongoClient As %SYS.Python;

/// json.dumps reference
Property JsonDumps As %SYS.Python;

/// json.loads reference
Property JsonLoads As %SYS.Python;

/// datetime.datetime reference
Property Datetime As %SYS.Python;

/// datetime.date reference
Property Date As %SYS.Python;

/// bson.ObjectId reference
Property ObjectId As %SYS.Python;

Parameter SETTINGS = "MongoUri:MongoDB,ConnectTimeout:MongoDB,Credentials:MongoDB:credentialsSelector";

Method OnInit() As %Status
{
    #dim sc As %Status = $$$OK
    try {
        set ..Uri = ..MongoUri
        if ..Credentials'="" set ..Uri=..GetUri(..Uri,..Credentials)
        do ..PyInit()
        Set tConn = ..ValidateConnection(..Uri)  
        If tConn'=1 Throw ##Class(%Exception.StatusException).CreateFromStatus($$$ERROR($$$GeneralError,"<Invalid MongoDb Connection> "_$P(tConn,":",2)))
    } catch ex {
        set sc = ex.AsStatus()
    }
    quit sc
}

/// Connect to pymongo
Method PyInit() [ Language = python ]
{
    from pymongo import MongoClient
    from json import dumps, loads
    self.MongoClient = MongoClient
    self.JsonDumps = dumps
    self.JsonLoads = loads
    from datetime import datetime, date
    self.Datetime = datetime
    self.Date = date
    from bson import ObjectId
    self.ObjectId = ObjectId
}

/// return a %DynamicArray ResultSet from MongoDB
/// query is the dictionary for filtering
/// fields is the projection (empty json for all properties)
/// sort is for ordering (empty json for default order)
/// limit is the N first records. Default is 0 for all
Method Query(dbName, collectionName, query As %DynamicObject, fields As %DynamicObject, sort As %DynamicObject, limit As %Integer = 0) As %DynamicObject [ WebMethod ]
{
    if '$Data(query)||'$IsObject(query) set query = {}
    if '$Data(fields)||'$IsObject(fields) set fields = {}
    if '$Data(sort)||'$IsObject(sort) set sort = {}
    if '$Data(limit) set limit = 0
    set tMongoResultSet = ..QueryMongoDB(..Uri,dbName,collectionName, query.%ToJSON(), fields.%ToJSON(), sort.%ToJSON(), limit)
    quit [].%FromJSON(tMongoResultSet)
}

/// objOrArray is the obj or array to be inserted or updated(one or more values) 
/// for update set filterForUpdate (can be individual(ex:_id) or many)
Method InsertOrUpdate(dbName, collectionName, objOrArray As %DynamicObject, filterForUpdate As %DynamicObject) As %DynamicObject [ WebMethod ]
{
    if '$Data(filterForUpdate)||'$IsObject(filterForUpdate) set filterForUpdate = {}
    set result = ..InsertOrUpdateMongoDB(..Uri, dbName, collectionName, objOrArray.%ToJSON(),filterForUpdate.%ToJSON())
    quit {}.%FromJSON(result)
}

/// for mongoDB deletion (filter the object or objects to delete)
/// deleteMany is false by default
Method Delete(dbName, collectionName, filter As %DynamicObject, deleteMany = 0) As %DynamicObject [ WebMethod ]
{
    if '$Data(deleteMany) set deleteMany = 0
    set result = ..DeleteMongoDB(..Uri, dbName, collectionName,filter.%ToJSON(), deleteMany)
    quit {}.%FromJSON(result)
}

/// given an mongo uri connection string, replaces <db_user> and <db_password> for IRIS credentials
ClassMethod GetUri(uri As %String, credentials As %String) As %String
{
    set tUri = uri
    set tClassname=$zobjmethod($this,"%ClassName",1) 
    set tSC=##Class(Ens.Config.Credentials).GetCredentialsObj(.tCred,tClassname,"Ens.Config.Credentials",credentials)
    If 'tSC { Throw ##Class(%Exception.StatusException).CreateFromStatus(tSC) }
    set tUri=$Replace($Replace($Replace($Replace($Replace($Replace($Replace(tUri,"<user>","<usr>"),"<db_user>","<usr>"),"<username>","<usr>"),"<password>","<pwd>"),"<db_password>","<pwd>"),"<pwd>",tCred.PasswordGet()),"<usr>",tCred.Username)
    quit tUri
}

/// for mongoDB deletion (filter the object or objects to delete)
/// deleteMany is false by default
Method DeleteMongoDB(uri, dbName, collectionName, filter, deleteMany) As %SYS.Python [ Language = python ]
{
    if not deleteMany:
        deleteMany = 0

    def is_iso_format(value):
        if not isinstance(value, str):
            return False
        if len(value) < 10 or value[4] != "-" or value[7] != "-":
            return False
        try:
            self.Datetime.fromisoformat(value)
            return True
        except ValueError:
            return False

    def object_hook(d):
        for key, value in d.items():
            if is_iso_format(value):
                try:
                    # Try to convert strings to ISO datetime
                    d[key] = self.Datetime.fromisoformat(value)
                except ValueError:
                    pass  # ignore
            if isinstance(value, str) and len(value) == 24:
                try:
                    d[key] = self.ObjectId(value)
                except Exception:
                    pass  # ignore
        return d

    def json_serial(obj):
        if isinstance(obj, (self.Datetime, self.Date)):
            return obj.isoformat()
        if isinstance(obj, self.ObjectId):
            return str(obj)
        raise TypeError ("Type %s not serializable" % type(obj))

    client = self.MongoClient(uri)
    db = client[dbName] 
    collection = db[collectionName]    
    filter = self.JsonLoads(filter, object_hook=object_hook)

    if deleteMany == 1:
        res = collection.delete_many(filter)
    else:
        res = collection.delete_one(filter)

    client.close()
    response = {
        "deleted_count": res.deleted_count,  
        "acknowledged": res.acknowledged  
    }
    return self.JsonDumps(response,default=json_serial)
}

/// jsonObjOrArray is the obj or array to be inserted or updated(one or more values) 
/// for update set filterForUpdate (can be individual(ex:_id) or many)
Method InsertOrUpdateMongoDB(uri, dbName, collectionName, jsonObjorArray, filterForUpdate) As %SYS.Python [ Language = python ]
{
    def is_iso_format(value):
        if not isinstance(value, str):
            return False
        if len(value) < 10 or value[4] != "-" or value[7] != "-":
            return False
        try:
            self.Datetime.fromisoformat(value)
            return True
        except ValueError:
            return False

    def object_hook(d):
        for key, value in d.items():
            if is_iso_format(value):
                try:
                    # Try to convert strings to ISO datetime
                    d[key] = self.Datetime.fromisoformat(value)
                except ValueError:
                    pass  # ignore
            if isinstance(value, str) and len(value) == 24:
                try:
                    d[key] = self.ObjectId(value)
                except Exception:
                    pass  # ignore
        return d

    def json_serial(obj):
        if isinstance(obj, (self.Datetime, self.Date)):
            return obj.isoformat()
        if isinstance(obj, self.ObjectId):
            return str(obj)
        raise TypeError ("Type %s not serializable" % type(obj))

    client = self.MongoClient(uri)
    db = client[dbName] 
    collection = db[collectionName]    
    newData = self.JsonLoads(jsonObjorArray, object_hook=object_hook)
    filter = self.JsonLoads(filterForUpdate, object_hook=object_hook)

    if filter:
        newData = {"$set": newData}
        res = collection.update_many(filter,newData)
    elif type(newData) is dict:
        res = collection.insert_one(newData)
    elif type(newData) is list:
        res = collection.insert_many(newData)

    client.close()
    if filter:
        response = {
            "matched_count": res.matched_count,  
            "modified_count": res.modified_count,  
            "acknowledged": res.acknowledged  
        }
    elif type(newData) is dict:
        response = {
                "message": "Success",
                "inserted_id": res.inserted_id
        }
    elif type(newData) is list:
        response = {
                "message": "Success",
                "inserted_ids": res.inserted_ids
        }
    return self.JsonDumps(response,default=json_serial)
}

/// return a %DynamicArray ResultSet from MongoDB
/// query is the dictionary for filtering
/// fields is the projection (empty json for all properties)
/// sort is for ordering (empty json for default order)
/// limit is the N first records. Default is 0 for all
Method QueryMongoDB(uri, dbName, collectionName, query, fields, sort, limit) As %SYS.Python [ Language = python ]
{
    def is_iso_format(value):
        if not isinstance(value, str):
            return False
        if len(value) < 10 or value[4] != "-" or value[7] != "-":
            return False
        try:
            self.Datetime.fromisoformat(value)
            return True
        except ValueError:
            return False

    def object_hook(d):
        for key, value in d.items():
            if is_iso_format(value):
                try:
                    # Try to convert strings to ISO datetime
                    d[key] = self.Datetime.fromisoformat(value)
                except ValueError:
                    pass  # ignore
            if isinstance(value, str) and len(value) == 24:
                try:
                    d[key] = self.ObjectId(value)
                except Exception:
                    pass  # ignore
        return d

    def json_serial(obj):
        if isinstance(obj, (self.Datetime, self.Date)):
            return obj.isoformat()
        if isinstance(obj, self.ObjectId):
            return str(obj)
        raise TypeError ("Type %s not serializable" % type(obj))

    query = self.JsonLoads(query, object_hook=object_hook)
    fields = self.JsonLoads(fields)
    sort = self.JsonLoads(sort)

    client = self.MongoClient(uri)
    db = client[dbName] 
    collection = db[collectionName]    
    results = collection.find(query, fields)
    if sort:
        results = results.sort(sort)
    if limit>0:
        results = results.limit(limit)
    res = []
    for record in results:
        res.append(record)
    client.close()
    return self.JsonDumps(res,default=json_serial)
}

/// Validates the mongo connection, given an uri connection string
Method ValidateConnection(uri, timeout = 5) As %SYS.Python [ Language = python ]
{
    if not timeout:
        timeout = 5

    from pymongo.errors import ConnectionFailure, InvalidURI

    def validate(uri):
        try:
            client = self.MongoClient(uri, serverSelectionTimeoutMS=timeout*1000)  
            client.server_info()  # Force an execution
            return "1"
        except InvalidURI:
            return "0:Invalid Connection String"
        except ConnectionFailure:
            return "0:Not Possible to Connect to MongoDB"
        except Exception as e:
            return "0:Unknown Error"

    return validate(uri)
}

}
