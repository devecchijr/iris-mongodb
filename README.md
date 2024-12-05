# iris-mongodb
Interoperates with MongoDB (via pymongo package) with InterSystems IRIS (including outbound adapter)

implementation example [here](/src/test.cls)
```
NAMESPACE> do ##class(custom.python.pymongo.test).TestMongoDBCrud()
```

ps: It's compatible with IRIS versions that supports embedded python.
