/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_986407980")

  // add field
  collection.fields.addAt(15, new Field({
    "autogeneratePattern": "",
    "help": "",
    "hidden": false,
    "id": "text8529675",
    "max": 6000,
    "min": 0,
    "name": "shared_documents",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_986407980")

  // remove field
  collection.fields.removeById("text8529675")

  return app.save(collection)
})
