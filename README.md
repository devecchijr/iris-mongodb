# iris-mongodb
Interoperates with MongoDB (via pymongo package) with InterSystems IRIS (including outbound adapter)

Remember to import [pymongo](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=AFL_epython#AFL_epython_pylibrary_install) package.

implementation example for testing [here](/src/test.cls)
```
NAMESPACE> do ##class(custom.python.pymongo.test).TestMongoDBCrud()
```

for interoperability, use the following adapter in your business operation:

```
Parameter ADAPTER = "custom.python.pymongo.outboundAdapter";

Parameter INVOCATION = "Queue";
```

Query example: 
```
/// parameters: (dbName, collectionName, query, fields, sort, limit) => query, fields and sort are %DynamicObjects
/// resultset is an array of objects (%DynamicArray)
set resultset = ..Adapter.Query("mydb","mycollection", {"_id":(tId)})
```

Insert example:
```
set newUser = {
            "name":"Claudio Devecchi Junior",
            "email":"devechi@inters.com"
}
/// parameters: (dbName, collectionName, objOrArray, filterForUpdate) => objOrArray and filterForUpdate are %DynamicObjects
/// insertResponse is an object with the inserted id/ids (%DynamicObject)
set insertResponse = ..Adapter.InsertOrUpdate("sample_mflix", "users", newUser)
```

Update example:
```
set newValues = {"email":"claudio.devechi@inter.com"}
set filter = {"_id":(tObjectId)} //is the filter for update
/// parameters: (dbName, collectionName, objOrArray, filterForUpdate) => objOrArray and filterForUpdate are %DynamicObjects
/// filterForUpdate defines update action
/// updateResponse is an object with the updated id/ids (%DynamicObject)
set updateResponse =..Adapter.InsertOrUpdate("sample_mflix", "users", newValues, filter)
```

Delete example:
```
set filter = {"_id":(tObjectId)} //is the filter for deletion
/// parameters: (dbName, collectionName, filter,  deleteMany) => filter is %DynamicObject. deleteMany is false by default
/// deleteResponse is an object with the deleted information (%DynamicObject)
set deleteResponse =..Adapter.Delete("sample_mflix", "users", filter)
```

ps: It's compatible with IRIS versions that supports embedded python.
