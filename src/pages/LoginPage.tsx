import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Pill, Mail, Lock, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Checkbox } from '@/components/ui/Checkbox';
import { supabase } from '@/lib/supabase';

const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(error.message);
    }
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen w-full lg:grid lg:grid-cols-2">
      <div className="flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <motion.div 
          className="w-full max-w-md space-y-8"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div>
            <div className="flex items-center justify-center text-primary">
              <Pill className="h-10 w-10" />
            </div>
            <h1 className="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900">
              B-Pharma POS
            </h1>
            <h2 className="mt-2 text-center text-lg font-medium text-gray-700">
              Sign in to your account
            </h2>
          </div>
          <form className="mt-8 space-y-6" onSubmit={handleLogin}>
            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative flex items-center" role="alert">
                <AlertCircle className="h-5 w-5 mr-2" />
                <span className="block sm:inline">{error}</span>
              </div>
            )}
            <div className="rounded-md shadow-sm -space-y-px">
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                <Input
                  id="email-address"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  className="pl-10 !rounded-b-none"
                  placeholder="Email address"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={loading}
                />
              </div>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
                <Input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  className="pl-10 !rounded-t-none"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Checkbox id="remember-me" disabled={loading} />
                <label htmlFor="remember-me" className="ml-2 block text-sm text-gray-900">
                  Remember me
                </label>
              </div>

              <div className="text-sm">
                <a href="#" className="font-medium text-primary hover:text-primary/90">
                  Forgot your password?
                </a>
              </div>
            </div>

            <div>
              <Button type="submit" className="w-full" size="lg" disabled={loading}>
                {loading ? 'Signing in...' : 'Sign in'}
              </Button>
            </div>
          </form>
        </motion.div>
      </div>
      <div className="hidden bg-gray-50 lg:block">
        <motion.img
          className="h-full w-full object-cover"
          src="https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=2574&auto=format&fit=crop"
          alt="Pharmacist organizing medication"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.2 }}
        />
      </div>
    </div>
  );
};

export default LoginPage;
