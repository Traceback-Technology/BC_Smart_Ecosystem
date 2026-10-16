const Admin = require('../models/Admin');
const createCrudController = require('./CRUDFactory');

//create, getAll, getById, updateById, deleteById
const base = createCrudController(Admin);

// Find one admin by email
const findByEmail = async (email) => {
    return Admin.findOne({ email: email.toLowerCase().trim() });
};

//Everyone with a given rolw
const getByRole = async (role) => {
    return Admin.find({ role: role });
};

//change one admin's role
const setRole = async (adminId, role) => {
    return Admin.findByIdAndUpdate(adminId, { $set: { role } }, { returnDocument: 'after', runValidators: true } );  //runvalidators ensures the role is one of the allowed values and ensures the enum applis to updates
};


module.exports = {
    ...base,
    findByEmail,
    getByRole,
    setRole
};