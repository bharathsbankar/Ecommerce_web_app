import React from 'react';
import { Package, Plus, Minus } from 'lucide-react';

export default function StorePage({ 
  products, 
  cart, 
  loadingProducts, 
  gridQuantities, 
  setGridQuantities, 
  handleAddToCart, 
  handleUpdateCartQuantity,
  fetchProducts 
}) {
  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
          ⚡ Hot Flash Deals <span className="text-xs bg-red-500 text-white font-extrabold px-2 py-0.5 rounded-full uppercase tracking-wider animate-pulse">Limited Stock</span>
        </h1>
        <button 
          onClick={fetchProducts}
          className="text-xs text-flipkart-blue font-bold hover:underline"
        >
          Refresh Inventory
        </button>
      </div>

      {loadingProducts ? (
        <div className="flex flex-col items-center justify-center py-20">
          <div className="h-10 w-10 border-4 border-flipkart-blue border-t-transparent rounded-full animate-spin"></div>
          <p className="mt-4 text-gray-500 text-sm">Loading deal inventory...</p>
        </div>
      ) : products.length === 0 ? (
        <div className="bg-white rounded border p-10 text-center shadow-sm">
          <p className="text-gray-500">No active products found in the catalog.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
          {products.map(p => {
            const currentQty = gridQuantities[p.id] || 1;
            const itemInCart = cart.find(ci => ci.productId === p.id);
            const isOutOfStock = p.stockQuantity <= 0;

            return (
              <div key={p.id} className="bg-white rounded border border-gray-200 shadow-sm flex flex-col justify-between overflow-hidden hover-card-trigger">
                {/* Product Thumbnail Placeholder */}
                <div className="bg-gray-100 h-44 flex items-center justify-center text-flipkart-blue">
                  <span className="text-5xl">📦</span>
                </div>

                {/* Details */}
                <div className="p-4 flex-1 flex flex-col justify-between">
                  <div>
                    <div className="flex justify-between items-start">
                      <h2 className="font-bold text-lg text-gray-900 leading-snug">{p.name}</h2>
                      <span className="font-black text-xl text-gray-900">₹{p.price.toLocaleString('en-IN')}</span>
                    </div>
                    <p className="text-gray-500 text-sm mt-1 line-clamp-2">{p.description}</p>
                  </div>

                  <div className="mt-4 pt-4 border-t border-gray-100">
                    {/* Stock Info */}
                    <div className="flex justify-between items-center mb-3">
                      <span className="text-xs font-semibold text-gray-500">Displayed Stock:</span>
                      {isOutOfStock ? (
                        <span className="text-xs font-black text-red-500 bg-red-50 px-2 py-0.5 rounded uppercase">Out of Stock</span>
                      ) : (
                        <span className="text-xs font-black text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">
                          {p.stockQuantity} Available
                        </span>
                      )}
                    </div>

                    {/* Action Controller */}
                    {itemInCart ? (
                      <div className="flex items-center justify-between bg-flipkart-lightBlue p-2 rounded-sm">
                        <span className="text-xs font-bold text-flipkart-blue">Added to Cart</span>
                        <div className="flex items-center gap-2">
                          <button 
                            onClick={() => handleUpdateCartQuantity(p.id, itemInCart.quantity - 1)}
                            className="p-1 bg-white border rounded hover:bg-gray-100"
                          >
                            <Minus className="h-3 w-3" />
                          </button>
                          <span className="text-sm font-bold font-mono">{itemInCart.quantity}</span>
                          <button 
                            onClick={() => handleUpdateCartQuantity(p.id, itemInCart.quantity + 1)}
                            className="p-1 bg-white border rounded hover:bg-gray-100"
                            disabled={itemInCart.quantity >= p.stockQuantity + itemInCart.quantity}
                          >
                            <Plus className="h-3 w-3" />
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-center gap-2">
                        {/* Quantity bounded input */}
                        <div className="flex items-center border rounded overflow-hidden">
                          <button 
                            onClick={() => setGridQuantities(prev => ({ ...prev, [p.id]: Math.max(1, currentQty - 1) }))}
                            className="px-2 py-1 bg-gray-50 border-r hover:bg-gray-100"
                            disabled={isOutOfStock}
                          >
                            -
                          </button>
                          <span className="px-3 py-1 font-semibold text-sm font-mono">{isOutOfStock ? 0 : currentQty}</span>
                          <button 
                            onClick={() => setGridQuantities(prev => ({ ...prev, [p.id]: Math.min(p.stockQuantity, currentQty + 1) }))}
                            className="px-2 py-1 bg-gray-50 border-l hover:bg-gray-100"
                            disabled={isOutOfStock || currentQty >= p.stockQuantity}
                          >
                            +
                          </button>
                        </div>

                        <button
                          onClick={() => handleAddToCart(p.id, currentQty)}
                          disabled={isOutOfStock}
                          className={`flex-1 text-center py-1.5 text-sm font-bold rounded-sm shadow-sm transition-colors uppercase ${isOutOfStock ? 'bg-gray-200 text-gray-400 cursor-not-allowed' : 'bg-flipkart-yellow text-flipkart-blue hover:bg-yellow-400'}`}
                        >
                          Add to Cart
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
