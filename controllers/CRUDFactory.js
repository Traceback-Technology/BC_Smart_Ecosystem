//reusable CRUD controller factory function that takes a Mongoose model as an argument and returns an object with methods for creating, reading, updating, and deleting documents in the database
function createCRUDController(Model) {
  return {
    // Create a new document
    create: async(data) => {
        const doc = new Model(data);
        return doc.save();
    },

    // Get all documents with optional filtering, sorting, and pagination
    getAll: async(filter = {}, options = {}) => {
        const { sort, skip, limit } = options;
        return Model.find(filter).sort(sort).skip(skip).limit(limit);
    },

    // Get a document by its ID
    getById: async(id) => {
        return Model.findById(id);
    },

    // Update a document by its ID
    updateById: async(id, updates) => {
        return Model.findByIdAndUpdate(id, { $set: updates }, { returnDocument: 'after' });
    },

    // Delete a document by its ID
    deleteById: async(id) => {
        return Model.findByIdAndDelete(id);
    },

    // Get a single document based on a filter
    getOne: async(filter) => {
        return Model.findOne(filter);
    },

    // Count documents based on a filter
    count: async(filter = {}) => {
        return Model.countDocuments(filter);
    },

    };
}

module.exports = createCRUDController;