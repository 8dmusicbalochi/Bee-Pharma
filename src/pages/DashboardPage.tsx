import React from 'react';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/Button';
import { motion } from 'framer-motion';

const DashboardPage: React.FC = () => {
  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  const user = supabase.auth.getUser();

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-4">
      <motion.div 
        className="w-full max-w-md p-8 bg-white shadow-lg rounded-xl text-center"
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.4 }}
      >
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Welcome Back!</h1>
        <p className="text-gray-600 mb-6">You are now logged into B-Pharma POS.</p>
        <Button onClick={handleLogout} variant="destructive" size="lg">
          Sign Out
        </Button>
      </motion.div>
    </div>
  );
};

export default DashboardPage;
