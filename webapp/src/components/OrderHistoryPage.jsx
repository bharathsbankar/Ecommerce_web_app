import React from 'react';
import { ShoppingBag } from 'lucide-react';

export default function OrderHistoryPage({ orders, loadingOrders }) {
  const formatDate = (dateVal) => {
    if (!dateVal) return '';
    if (typeof dateVal === 'number') {
      return new Date(dateVal * 1000).toLocaleString('en-IN');
    }
    if (!isNaN(dateVal)) {
      return new Date(parseFloat(dateVal) * 1000).toLocaleString('en-IN');
    }
    return new Date(dateVal).toLocaleString('en-IN');
  };

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-2">
        <ShoppingBag className="h-6 w-6 text-flipkart-blue" /> Order History
      </h1>

      {loadingOrders ? (
        <div className="flex flex-col items-center justify-center py-20">
          <div className="h-10 w-10 border-4 border-flipkart-blue border-t-transparent rounded-full animate-spin"></div>
          <p className="mt-4 text-gray-500 text-sm">Fetching your purchase receipts...</p>
        </div>
      ) : orders.length === 0 ? (
        <div className="bg-white rounded border p-12 text-center shadow-sm">
          <ShoppingBag className="h-16 w-16 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">You haven't placed any orders yet.</p>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map(order => (
            <div key={order.id} className="bg-white rounded border border-gray-200 overflow-hidden shadow-sm">
              {/* Header */}
              <div className="bg-gray-50 px-4 py-3 border-b flex flex-wrap justify-between items-center gap-4 text-sm">
                <div className="flex gap-6">
                  <div>
                    <p className="text-gray-500 text-xs uppercase font-semibold">Order ID</p>
                    <p className="font-bold text-gray-800">#{order.id}</p>
                  </div>
                  <div>
                    <p className="text-gray-500 text-xs uppercase font-semibold">Date Placed</p>
                    <p className="font-medium text-gray-800">
                      {formatDate(order.createdAt)}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-gray-500 text-xs uppercase font-semibold">Grand Total</p>
                  <p className="text-base font-black text-flipkart-blue">₹{order.grandTotal.toLocaleString('en-IN')}</p>
                </div>
              </div>

              {/* Items */}
              <div className="divide-y divide-gray-100">
                {order.items.map(item => {
                  return (
                    <div key={item.id} className="p-4 flex gap-4 items-center justify-between text-sm">
                      <div className="flex gap-3 items-center">
                        <div className="h-10 w-10 bg-gray-100 rounded flex items-center justify-center text-lg">
                          📦
                        </div>
                        <div>
                          <h3 className="font-semibold text-gray-900">Product ID: {item.productId}</h3>
                          <p className="text-xs text-gray-500">Quantity: {item.quantity}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-gray-800">₹{(item.perUnitPrice * item.quantity).toLocaleString('en-IN')}</p>
                        <p className="text-xs text-gray-400">Paid: ₹{item.perUnitPrice} each</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
