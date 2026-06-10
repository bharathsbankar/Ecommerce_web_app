import React from 'react';
import { useAuth } from '../context/AuthContext';
import { ShoppingCart, LogOut, ShoppingBag, Settings, Package } from 'lucide-react';

export default function Navbar({ activeTab, setActiveTab, cartCount, onLoginClick }) {
  const { user, logout } = useAuth();

  return (
    <header className="bg-flipkart-blue text-white sticky top-0 z-40 shadow-md">
      <div className="max-w-6xl mx-auto px-4 py-3 flex justify-between items-center gap-4">
        {/* Logo */}
        <div className="flex items-center gap-2 cursor-pointer" onClick={() => setActiveTab('products')}>
          <span className="text-2xl font-bold italic tracking-wide flex items-center">
            Flash<span className="text-flipkart-yellow font-black not-italic">Dash</span>
            <span className="text-flipkart-yellow text-xl ml-1">⚡</span>
          </span>
        </div>

        {/* Nav Buttons */}
        <nav className="flex items-center gap-6">
          <button 
            onClick={() => setActiveTab('products')} 
            className={`text-sm font-semibold flex items-center gap-1 hover:text-flipkart-yellow transition-colors ${activeTab === 'products' ? 'text-flipkart-yellow' : ''}`}
          >
            <Package className="h-4 w-4" /> Store
          </button>

          {user && (
            <>
              <button 
                onClick={() => setActiveTab('cart')} 
                className={`text-sm font-semibold flex items-center gap-1.5 hover:text-flipkart-yellow transition-colors relative ${activeTab === 'cart' ? 'text-flipkart-yellow' : ''}`}
              >
                <ShoppingCart className="h-4 w-4" /> 
                Cart
                {cartCount > 0 && (
                  <span className="absolute -top-2.5 -right-3.5 bg-flipkart-yellow text-flipkart-blue text-xs font-extrabold px-1.5 py-0.5 rounded-full border border-flipkart-blue animate-bounce">
                    {cartCount}
                  </span>
                )}
              </button>

              <button 
                onClick={() => setActiveTab('history')} 
                className={`text-sm font-semibold flex items-center gap-1 hover:text-flipkart-yellow transition-colors ${activeTab === 'history' ? 'text-flipkart-yellow' : ''}`}
              >
                <ShoppingBag className="h-4 w-4" /> Orders
              </button>

              {user.role === 'admin' && (
                <button 
                  onClick={() => setActiveTab('admin')} 
                  className={`text-sm font-semibold flex items-center gap-1 hover:text-flipkart-yellow transition-colors ${activeTab === 'admin' ? 'text-flipkart-yellow' : ''}`}
                >
                  <Settings className="h-4 w-4" /> Admin
                </button>
              )}
            </>
          )}

          {/* Auth section */}
          <div className="flex items-center gap-2 border-l border-white/20 pl-4">
            {user ? (
              <div className="flex items-center gap-3">
                <div className="flex flex-col text-right">
                  <span className="text-xs text-slate-200">Hello,</span>
                  <span className="text-xs font-bold text-flipkart-yellow truncate max-w-[120px]">
                    {user.username} ({user.role})
                  </span>
                </div>
                <button 
                  onClick={logout}
                  className="p-1.5 rounded-full bg-white/10 hover:bg-white/20 transition-all"
                  title="Logout"
                >
                  <LogOut className="h-4 w-4 text-white" />
                </button>
              </div>
            ) : (
              <button 
                onClick={onLoginClick}
                className="bg-white text-flipkart-blue px-5 py-1 text-sm font-semibold rounded-sm hover:bg-slate-100 transition-colors shadow-sm"
              >
                Login
              </button>
            )}
          </div>
        </nav>
      </div>
    </header>
  );
}
