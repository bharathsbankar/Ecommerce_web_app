import React, { useState, useEffect, useRef } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import api from './api';
import { Clock } from 'lucide-react';

import Navbar from './components/Navbar';
import StorePage from './components/StorePage';
import CartPage from './components/CartPage';
import OrderHistoryPage from './components/OrderHistoryPage';
import AdminDashboard from './components/AdminDashboard';
import AuthModal from './components/AuthModal';

function MainApp() {
  const { user, logout } = useAuth();
  
  // Navigation & UI States
  const [activeTab, setActiveTab] = useState('products');
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authMode, setAuthMode] = useState('login'); // 'login' | 'register'

  // Business Data States
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [orders, setOrders] = useState([]);
  const [loadingProducts, setLoadingProducts] = useState(true);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [isCheckingOut, setIsCheckingOut] = useState(false);

  // Soft-reservation Countdown Timer
  const [reservationTime, setReservationTime] = useState(null);
  const timerRef = useRef(null);

  // Quantities selected in Catalog Grid (maps productId -> input quantity)
  const [gridQuantities, setGridQuantities] = useState({});

  // Initialize
  useEffect(() => {
    fetchProducts(true);
    if (user) {
      fetchCart();
      if (user.role === 'admin') {
        setActiveTab('admin');
      }
    } else {
      setCart([]);
      setReservationTime(null);
      if (activeTab === 'admin' || activeTab === 'history' || activeTab === 'cart') {
        setActiveTab('products');
      }
    }
  }, [user]);

  // Reservation Countdown Logic
  useEffect(() => {
    if (cart.length > 0) {
      if (!timerRef.current) {
        setReservationTime(300); // 5 minutes
      }
    } else {
      setReservationTime(null);
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    }
  }, [cart]);

  useEffect(() => {
    if (reservationTime !== null) {
      if (reservationTime > 0) {
        timerRef.current = setTimeout(() => {
          setReservationTime(prev => prev - 1);
        }, 1000);
      } else {
        alert("Your 5-minute cart reservation has expired. Stock has been returned to catalog.");
        fetchCart();
        fetchProducts();
      }
    }
    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, [reservationTime]);

  const fetchProducts = async (showSpinner = false) => {
    if (showSpinner) setLoadingProducts(true);
    try {
      const res = await api.get('/api/products');
      setProducts(res.data);
    } catch (err) {
      console.error('Error fetching products:', err);
    } finally {
      if (showSpinner) setLoadingProducts(false);
    }
  };

  const fetchCart = async () => {
    if (!user) return;
    try {
      const res = await api.get('/api/cart');
      setCart(res.data.items || []);
      const initialQtys = {};
      (res.data.items || []).forEach(item => {
        initialQtys[item.productId] = item.quantity;
      });
      setGridQuantities(prev => ({ ...prev, ...initialQtys }));
    } catch (err) {
      console.error('Error fetching cart:', err);
    }
  };

  const fetchOrders = async () => {
    if (!user) return;
    setLoadingOrders(true);
    try {
      const res = await api.get('/api/orders/history');
      setOrders(res.data);
    } catch (err) {
      console.error('Error fetching orders:', err);
    } finally {
      setLoadingOrders(false);
    }
  };

  // Cart Handlers
  const handleAddToCart = async (productId, quantity) => {
    if (!user) {
      alert("Create an account to continue shopping.");
      setAuthMode('login');
      setShowAuthModal(true);
      return;
    }

    try {
      const targetQty = parseInt(quantity, 10);
      await api.post('/api/cart', { productId, quantity: targetQty });
      await fetchCart();
      await fetchProducts();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to update cart');
    }
  };

  const handleUpdateCartQuantity = async (productId, newQuantity) => {
    if (newQuantity < 0) return;
    try {
      await api.post('/api/cart', { productId, quantity: newQuantity });
      setReservationTime(300); // Reset timer to 5 minutes on update
      await fetchCart();
      await fetchProducts();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to update quantity');
    }
  };

  const handleRemoveFromCart = async (productId) => {
    try {
      await api.delete(`/api/cart/${productId}`);
      await fetchCart();
      await fetchProducts();
    } catch (err) {
      alert('Failed to remove item');
    }
  };

  // Checkout Handler
  const handleCheckout = async () => {
    if (cart.length === 0) return;
    setIsCheckingOut(true);
    
    // Simulate payment authorization processing spinner (2 seconds)
    setTimeout(async () => {
      try {
        const response = await api.post('/api/orders/checkout');
        alert(`Checkout completed successfully! Order ID: ${response.data.id}`);
        setCart([]);
        setReservationTime(null);
        await fetchProducts();
        setActiveTab('history');
        fetchOrders();
      } catch (err) {
        alert(err.response?.data || 'Checkout failed');
        fetchCart();
        fetchProducts();
      } finally {
        setIsCheckingOut(false);
      }
    }, 2000);
  };

  // Helper to format countdown timer
  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // Find product helper
  const getProductDetails = (id) => {
    return products.find(p => p.id === id) || { name: `Product #${id}`, price: 0 };
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* 1. FLIPKART BRAND HEADER */}
      <Navbar 
        activeTab={activeTab} 
        setActiveTab={(tab) => {
          setActiveTab(tab);
          if (tab === 'cart') fetchCart();
          if (tab === 'history') fetchOrders();
        }}
        cartCount={cart.reduce((sum, item) => sum + item.quantity, 0)}
        onLoginClick={() => { setAuthMode('login'); setShowAuthModal(true); }}
      />

      {/* SOFT-RESERVATION BANNER */}
      {reservationTime !== null && (
        <div className="bg-yellow-50 border-b border-yellow-200 text-yellow-800 text-center py-2 text-sm font-medium flex items-center justify-center gap-2 animate-pulse">
          <Clock className="h-4 w-4 text-yellow-600 animate-spin" />
          <span>Flash deals are held in your cart temporarily. Completing purchase within: </span>
          <span className="font-bold text-base text-red-600 font-mono bg-yellow-100 px-2 py-0.5 rounded border border-yellow-300">
            {formatTime(reservationTime)}
          </span>
        </div>
      )}

      {/* MAIN CONTENT AREA */}
      <main className="flex-1 max-w-6xl w-full mx-auto px-4 py-8">
        
        {activeTab === 'products' && (
          <StorePage 
            products={products}
            cart={cart}
            loadingProducts={loadingProducts}
            gridQuantities={gridQuantities}
            setGridQuantities={setGridQuantities}
            handleAddToCart={handleAddToCart}
            handleUpdateCartQuantity={handleUpdateCartQuantity}
            fetchProducts={fetchProducts}
          />
        )}

        {activeTab === 'cart' && (
          <CartPage 
            cart={cart}
            getProductDetails={getProductDetails}
            handleUpdateCartQuantity={handleUpdateCartQuantity}
            handleRemoveFromCart={handleRemoveFromCart}
            handleCheckout={handleCheckout}
            setActiveTab={setActiveTab}
          />
        )}

        {activeTab === 'history' && (
          <OrderHistoryPage 
            orders={orders}
            loadingOrders={loadingOrders}
          />
        )}

        {activeTab === 'admin' && user && user.role === 'admin' && (
          <AdminDashboard 
            products={products}
            fetchProducts={fetchProducts}
          />
        )}
      </main>

      {/* FOOTER */}
      <footer className="bg-gray-900 text-gray-400 py-6 mt-12 border-t border-gray-800 text-center text-xs">
        <p>© 2026 FlashDash Deals. Created by pair programming with Antigravity AI.</p>
        <p className="mt-1 text-gray-600">Containerized Microservices architecture with private Docker bridge subnets and KrakenD API Gateway.</p>
      </footer>

      {/* 2. SECURE PAYMENT SIMULATION OVERLAY */}
      {isCheckingOut && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex flex-col items-center justify-center text-white animate-in fade-in duration-200">
          <div className="bg-slate-950 p-8 rounded-lg border border-slate-800 flex flex-col items-center max-w-sm text-center shadow-2xl relative overflow-hidden">
            <div className="h-14 w-14 border-4 border-flipkart-yellow border-t-transparent rounded-full animate-spin mb-6 shadow"></div>
            <h3 className="font-bold text-lg text-white mb-2">Simulating Secure Payment...</h3>
            <p className="text-slate-400 text-xs leading-relaxed">
              Verifying payment token via cryptographic rails, executing stock decrement, and clearing Redis holdings. Please wait.
            </p>
          </div>
        </div>
      )}

      {/* LOGIN/REGISTER MODAL */}
      <AuthModal 
        isOpen={showAuthModal}
        onClose={() => setShowAuthModal(false)}
        initialMode={authMode}
        onLoginSuccess={(userData) => {
          if (userData.role === 'admin') {
            setActiveTab('admin');
          } else {
            setActiveTab('products');
          }
        }}
      />
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <MainApp />
    </AuthProvider>
  );
}

export default App;
