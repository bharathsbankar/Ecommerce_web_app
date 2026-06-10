import React, { useState } from 'react';
import api from '../api';
import { Settings, AlertCircle, Edit, Trash } from 'lucide-react';

export default function AdminDashboard({ products, fetchProducts }) {
  const [editingProduct, setEditingProduct] = useState(null);
  const [adminName, setAdminName] = useState('');
  const [adminDesc, setAdminDesc] = useState('');
  const [adminPrice, setAdminPrice] = useState('');
  const [adminStock, setAdminStock] = useState('');
  const [adminError, setAdminError] = useState('');

  const handleSaveProduct = async (e) => {
    e.preventDefault();
    setAdminError('');

    if (!adminName || !adminPrice || adminStock === '') {
      setAdminError('Product name, price, and stock quantity are required.');
      return;
    }

    const priceNum = parseFloat(adminPrice);
    const stockNum = parseInt(adminStock, 10);

    if (isNaN(priceNum) || priceNum <= 0) {
      setAdminError('Price must be a valid positive number.');
      return;
    }
    if (isNaN(stockNum) || stockNum < 0) {
      setAdminError('Stock quantity must be a non-negative integer.');
      return;
    }

    const payload = {
      name: adminName,
      description: adminDesc,
      price: priceNum,
      stockQuantity: stockNum
    };

    try {
      if (editingProduct) {
        await api.put(`/api/products/${editingProduct.id}`, payload);
      } else {
        await api.post('/api/products', payload);
      }

      // Reset form
      setEditingProduct(null);
      setAdminName('');
      setAdminDesc('');
      setAdminPrice('');
      setAdminStock('');
      fetchProducts();
    } catch (err) {
      setAdminError(err.response?.data?.error || 'Failed to save product');
    }
  };

  const handleEditClick = (p) => {
    setEditingProduct(p);
    setAdminName(p.name);
    setAdminDesc(p.description || '');
    setAdminPrice(p.price.toString());
    setAdminStock(p.stockQuantity.toString());
  };

  const handleDeleteProduct = async (productId) => {
    if (!confirm('Are you sure you want to delete this product?')) return;
    try {
      await api.delete(`/api/products/${productId}`);
      fetchProducts();
    } catch (err) {
      alert('Failed to delete product');
    }
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <Settings className="h-6 w-6 text-flipkart-blue" /> Admin Catalog Management
      </h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Product Creator Form */}
        <div className="bg-white rounded border border-gray-200 p-5 shadow-sm h-fit">
          <h2 className="font-bold text-gray-900 text-lg border-b pb-3 mb-4">
            {editingProduct ? 'Edit Product' : 'Add New Product'}
          </h2>
          <form onSubmit={handleSaveProduct} className="space-y-4">
            {adminError && (
              <div className="bg-red-50 text-red-700 text-xs p-3 rounded flex items-center gap-2">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{adminError}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Product Name</label>
              <input 
                type="text" 
                value={adminName}
                onChange={e => { setAdminError(''); setAdminName(e.target.value); }}
                className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
                placeholder="e.g. Sony Headset"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Description</label>
              <textarea 
                value={adminDesc}
                onChange={e => setAdminDesc(e.target.value)}
                rows="3"
                className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
                placeholder="Product features, details"
              ></textarea>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Price (₹)</label>
                <input 
                  type="number" 
                  step="0.01"
                  value={adminPrice}
                  onChange={e => setAdminPrice(e.target.value)}
                  className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
                  placeholder="Price in INR"
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Stock Quantity</label>
                <input 
                  type="number" 
                  value={adminStock}
                  onChange={e => setAdminStock(e.target.value)}
                  className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
                  placeholder="Initial Stock"
                />
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <button 
                type="submit"
                className="flex-1 bg-flipkart-blue text-white py-2 rounded-sm text-sm font-bold hover:bg-blue-600 transition-colors uppercase"
              >
                {editingProduct ? 'Update Product' : 'Create Product'}
              </button>
              {editingProduct && (
                <button 
                  type="button"
                  onClick={() => {
                    setEditingProduct(null);
                    setAdminName('');
                    setAdminDesc('');
                    setAdminPrice('');
                    setAdminStock('');
                    setAdminError('');
                  }}
                  className="px-4 py-2 border rounded-sm text-sm font-semibold hover:bg-gray-100"
                >
                  Cancel
                </button>
              )}
            </div>
          </form>
        </div>

        {/* Products List Table */}
        <div className="lg:col-span-2 bg-white rounded border border-gray-200 shadow-sm overflow-hidden">
          <div className="px-4 py-3 border-b bg-gray-50 font-bold text-sm text-gray-900">
            Current Product Inventory
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-sm">
              <thead>
                <tr className="bg-gray-100 text-gray-600 text-xs font-bold uppercase border-b">
                  <th className="p-3">ID</th>
                  <th className="p-3">Name</th>
                  <th className="p-3">Price</th>
                  <th className="p-3">True Stock</th>
                  <th className="p-3 text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {products.map(p => (
                  <tr key={p.id} className="hover:bg-gray-50/50">
                    <td className="p-3 font-mono font-bold text-gray-500 text-xs">{p.id}</td>
                    <td className="p-3 font-semibold text-gray-900">{p.name}</td>
                    <td className="p-3 font-bold">₹{p.price.toLocaleString('en-IN')}</td>
                    <td className="p-3 text-gray-700 font-mono">{p.stockQuantity}</td>
                    <td className="p-3 text-center">
                      <div className="inline-flex gap-2">
                        <button 
                          onClick={() => handleEditClick(p)}
                          className="p-1.5 text-gray-600 hover:text-flipkart-blue hover:bg-blue-50 rounded"
                          title="Edit"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button 
                          onClick={() => handleDeleteProduct(p.id)}
                          className="p-1.5 text-gray-600 hover:text-red-500 hover:bg-red-50 rounded"
                          title="Delete"
                        >
                          <Trash className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
