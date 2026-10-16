const MenuItem = require('../models/MenuItem');
const createCrudController = require('./CRUDFactory');

const base = createCrudController(MenuItem);

//gettig all inventory levels, with optional category filtering
const getInventoryLevels = async (category = null) => {
    const filter = category ? { category } : {};
    return MenuItem.find(filter, { 
        name: 1, 
        category: 1,
        stockQuantity: 1, 
        lowStockThreshold: 1,
        isAvailable: 1,
 }).sort({ category: 1, name: 1 });
};

//getting all low stock items
const getLowStockItems = async () => {
  return MenuItem.find({
    $expr: { $lte: ['$stockQuantity', '$lowStockThreshold'] },
  }).sort({ stockQuantity: 1 });
};

module.exports = {
    ...base,
    getInventoryLevels,
    getLowStockItems
};