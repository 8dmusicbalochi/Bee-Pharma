import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';
import BottomNav from './BottomNav';

const pageTitles: { [key: string]: string } = {
  '/': 'Dashboard',
  '/pos': 'Point of Sale',
  '/sales': 'Sales History',
  '/inventory': 'Inventory',
  '/products': 'Products',
  '/categories': 'Categories',
  '/suppliers': 'Suppliers',
  '/purchase-orders': 'Purchase Orders',
  '/users': 'User Management',
  '/settings': 'Settings',
};

const MainLayout: React.FC = () => {
  const location = useLocation();
  const title = pageTitles[location.pathname] || 'B-Pharma POS';

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <Header title={title} />
        <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-20 md:pb-6">
          <Outlet />
        </main>
      </div>
      <BottomNav />
    </div>
  );
};

export default MainLayout;
