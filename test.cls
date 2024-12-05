/// Sample Method to show how to use mongodb crud methods from iris
/// the same applies to interop (custom.python.pymongo.outboundAdapter), but the uri and credentials are part of adapter/bo properties
/// example: ..Adapter.Query("mydb", "mycollection", {"_id":(tPatientId)})
Class custom.python.pymongo.test Extends %RegisteredObject
{

ClassMethod TestMongoDBCrud() As %Status
{
        Set sc = $$$OK
        Set mongoUri = "mongodb+srv://<db_user>:<db_password>@cluster0.y1uie.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0&tlsAllowInvalidCertificates=true"
        Set irisCredentials = "mongodb" //the connection must have been created or the user and pwd will be explicit in you connection string
        Write "=========================== Query Response ==============================",!
        /// query names that start with the A letter
        Set queryResponse = ##class(custom.python.pymongo.crud).Query(mongoUri, irisCredentials, "sample_mflix", "users", {"name": {"$regex": "^A", "$options": "i"}},{"_id":1,"name":1})
        Set cursor = queryResponse.%GetIterator()
        While (cursor.%GetNext(.key,.value)) {
            Write value.%ToJSON(),!
        }
        Write "=========================================================================",!!
        Write "========================== Insert Response ==============================",!
        /// insert a new user
        Set newUser = {
            "name":"Claudio Devecchi Junior",
            "email":"devecchi@intersystems.com"
        }
        // check if the user exists
        Set tClaudiosId = ""
        Set queryResponse = ##class(custom.python.pymongo.crud).Query(mongoUri, irisCredentials, "sample_mflix", "users", {"name":"Claudio Devecchi Junior"})
        If queryResponse.%Size()=0 {
            Set insertResponse = ##class(custom.python.pymongo.crud).InsertOrUpdate(mongoUri, irisCredentials, "sample_mflix", "users", newUser)
            Write insertResponse.%ToJSON(),!
            Set tClaudiosId = insertResponse.%Get("inserted_id")
        } else {
            Set tClaudiosId = queryResponse.%Get(0).%Get("_id")
            Write "Claudio Already Exists: _id: ",tClaudiosId,!
        }
        Write "=========================================================================",!!
        Write "========================== Update Response ==============================",!
        Write "Changes the email for _id: ",tClaudiosId,!
        Set beforeUpdateResponse = ##class(custom.python.pymongo.crud).Query(mongoUri, irisCredentials, "sample_mflix", "users", {"_id":(tClaudiosId)})
        Write "before update:",!
        Write beforeUpdateResponse.%ToJSON(),!
        Set updateResponse = ##class(custom.python.pymongo.crud).InsertOrUpdate(mongoUri, irisCredentials, "sample_mflix", "users", {"email":"claudio.devecchi@intersystems.com"}, {"_id":(tClaudiosId)})
        Write updateResponse.%ToJSON(),!
        Set afterUpdateResponse = ##class(custom.python.pymongo.crud).Query(mongoUri, irisCredentials, "sample_mflix", "users", {"_id":(tClaudiosId)})
        Write "after update:",!
        Write afterUpdateResponse.%ToJSON(),!
        Write "=========================================================================",!!
        Write "========================== Delete Response ==============================",!
        Set deleteResponse = ##class(custom.python.pymongo.crud).Delete(mongoUri, irisCredentials, "sample_mflix", "users", {"_id":(tClaudiosId)})
        Write deleteResponse.%ToJSON(),!
        Write "=========================================================================",!!
        Return sc
}

}
