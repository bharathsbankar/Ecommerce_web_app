import React from 'react';
import { ShoppingCart, Trash2 } from 'lucide-react';

export default function CartPage({ 
  cart, 
  getProductDetails, 
  handleUpdateCartQuantity, 
  handleRemoveFromCart, 
  handleCheckout,
  setActiveTab 
}) {
  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <ShoppingCart className="h-6 w-6 text-flipkart-blue" /> Your Shopping Cart
      </h1>

      {cart.length === 0 ? (
        <div className="bg-white rounded border p-12 text-center shadow-sm flex flex-col items-center">
          <ShoppingCart className="h-16 w-16 text-gray-300 mb-3" />
          <p className="text-gray-500 mb-4">Your cart is empty. Reserve hot deals before they sell out!</p>
          <button 
            onClick={() => setActiveTab('products')}
            className="bg-flipkart-blue text-white px-6 py-2 rounded-sm font-bold text-sm hover:bg-blue-600 transition-all uppercase"
          >
            Shop Deals Now
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Items List */}
          <div className="lg:col-span-2 space-y-4">
            {cart.map(item => {
              const p = getProductDetails(item.productId);
              const itemTotal = p.price * item.quantity;

              return (
                <div key={item.productId} className="bg-white rounded border border-gray-200 p-4 flex gap-4 items-center shadow-sm">
                  <div className="bg-gray-100 h-16 w-16 rounded flex items-center justify-center text-2xl">
                    📦
                  </div>
                  <div className="flex-1 flex flex-wrap justify-between items-center gap-4">
                    <div>
                      <h2 className="font-bold text-gray-950 leading-snug">{p.name}</h2>
                      <p className="text-xs text-gray-500 mt-0.5">Unit Price: ₹{p.price.toLocaleString('en-IN')}</p>
                    </div>

                    <div className="flex items-center gap-4">
                      {/* Quantity buttons */}
                      <div className="flex items-center border rounded">
                        <button 
                          onClick={() => handleUpdateCartQuantity(item.productId, item.quantity - 1)}
                          className="px-2 py-0.5 bg-gray-50 border-r hover:bg-gray-100"
                        >
                          -
                        </button>
                        <span className="px-3 py-0.5 font-bold font-mono text-sm">{item.quantity}</span>
                        <button 
                          onClick={() => handleUpdateCartQuantity(item.productId, item.quantity + 1)}
                          className="px-2 py-0.5 bg-gray-50 border-l hover:bg-gray-100"
                        >
                          +
                        </button>
                      </div>

                      <span className="font-bold text-gray-900 w-24 text-right">₹{itemTotal.toLocaleString('en-IN')}</span>

                      <button 
                        onClick={() => handleRemoveFromCart(item.productId)}
                        className="text-red-500 hover:text-red-700 p-1 hover:bg-red-50 rounded"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Price Breakdown Sidebar */}
          <div className="bg-white rounded border border-gray-200 shadow-sm p-5 h-fit">
            <h2 className="font-bold text-gray-500 uppercase text-xs tracking-wider border-b pb-3">Price Details</h2>
            <div className="space-y-3 mt-4">
              {cart.map(item => {
                const p = getProductDetails(item.productId);
                return (
                  <div key={item.productId} className="flex justify-between text-sm">
                    <span className="text-gray-600 truncate max-w-[180px]">{p.name} (x{item.quantity})</span>
                    <span className="font-medium text-gray-900">₹{(p.price * item.quantity).toLocaleString('en-IN')}</span>
                  </div>
                );
              })}

              <hr className="border-dashed" />

              <div className="flex justify-between font-bold text-base text-gray-900 pt-2 border-t">
                <span>Grand Total</span>
                <span className="text-xl text-flipkart-blue">
                  ₹{cart.reduce((sum, item) => sum + (getProductDetails(item.productId).price * item.quantity), 0).toLocaleString('en-IN')}
                </span>
              </div>
            </div>

            <button 
              onClick={handleCheckout}
              className="w-full mt-6 bg-flipkart-yellow text-flipkart-blue py-3 rounded-sm font-bold hover:bg-yellow-400 transition-colors uppercase shadow text-center tracking-wide"
            >
              Place Order (Buy)
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
