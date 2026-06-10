import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { AlertCircle, CheckCircle2 } from 'lucide-react';

export default function AuthModal({ isOpen, onClose, initialMode = 'login', onLoginSuccess }) {
  const { login, register } = useAuth();
  
  const [authMode, setAuthMode] = useState(initialMode); // 'login' | 'register'
  const [authEmail, setAuthEmail] = useState('');
  const [authUsername, setAuthUsername] = useState('');
  const [authPassword, setAuthPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [authSuccessMsg, setAuthSuccessMsg] = useState('');

  if (!isOpen) return null;

  const handleAuthSubmit = async (e) => {
    e.preventDefault();
    setAuthError('');
    setAuthSuccessMsg('');

    if (authMode === 'login') {
      const res = await login(authEmail, authPassword);
      if (res.success) {
        setAuthEmail('');
        setAuthPassword('');
        if (onLoginSuccess) {
          onLoginSuccess(res.user);
        }
        onClose();
      } else {
        setAuthError(res.error);
      }
    } else {
      const res = await register(authEmail, authUsername, authPassword);
      if (res.success) {
        setAuthSuccessMsg('Account created successfully! Please log in.');
        setAuthMode('login');
      } else {
        setAuthError(res.error);
      }
    }
  };

  return (
    <div className="fixed inset-0 bg-slate-900/50 backdrop-blur-xs z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded border border-gray-200 shadow-2xl max-w-md w-full overflow-hidden relative animate-in fade-in duration-200">
        {/* Left Brand Panel Aesthetic */}
        <div className="bg-flipkart-blue text-white px-6 py-5">
          <h3 className="text-xl font-bold italic flex items-center">
            Flash<span className="text-flipkart-yellow font-black not-italic">Dash</span>
            <span className="text-flipkart-yellow text-lg ml-1">⚡</span>
          </h3>
          <p className="text-xs text-blue-100 mt-1">
            {authMode === 'login' ? 'Login to access cart reservations, orders history and discounts.' : 'Create an account to shop limited-stock flash sale events!'}
          </p>
        </div>

        <form onSubmit={handleAuthSubmit} className="p-6 space-y-4">
          {authError && (
            <div className="bg-red-50 text-red-700 text-xs p-3 rounded flex items-center gap-2">
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{authError}</span>
            </div>
          )}
          {authSuccessMsg && (
            <div className="bg-emerald-50 text-emerald-700 text-xs p-3 rounded flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 shrink-0" />
              <span>{authSuccessMsg}</span>
            </div>
          )}

          <div>
            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Email Address</label>
            <input 
              type="email" 
              value={authEmail}
              onChange={e => { setAuthError(''); setAuthEmail(e.target.value); }}
              required
              className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
              placeholder="e.g. name@example.com"
            />
          </div>

          {authMode === 'register' && (
            <div>
              <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Username</label>
              <input 
                type="text" 
                value={authUsername}
                onChange={e => { setAuthError(''); setAuthUsername(e.target.value); }}
                required
                className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
                placeholder="e.g. shopking99"
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Password</label>
            <input 
              type="password" 
              value={authPassword}
              onChange={e => { setAuthError(''); setAuthPassword(e.target.value); }}
              required
              className="w-full border rounded px-3 py-1.5 text-sm focus:ring-1 focus:ring-flipkart-blue outline-none"
              placeholder="Password"
            />
          </div>

          <button 
            type="submit"
            className="w-full bg-flipkart-yellow text-flipkart-blue py-2.5 rounded-sm text-sm font-bold hover:bg-yellow-400 transition-colors uppercase shadow-sm tracking-wide mt-2"
          >
            {authMode === 'login' ? 'Login' : 'Sign Up'}
          </button>

          <div className="text-center pt-2 flex justify-between text-xs text-gray-500">
            <button 
              type="button"
              onClick={() => {
                setAuthMode(authMode === 'login' ? 'register' : 'login');
                setAuthError('');
                setAuthSuccessMsg('');
              }}
              className="text-flipkart-blue font-bold hover:underline"
            >
              {authMode === 'login' ? 'Create an account?' : 'Already have an account? Login'}
            </button>
            <button 
              type="button"
              onClick={onClose}
              className="hover:underline"
            >
              Close
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
