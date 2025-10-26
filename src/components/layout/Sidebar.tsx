import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  ShoppingCart,
  Boxes,
  ClipboardList,
  Tag,
  Users,
  Building,
  Truck,
  Settings,
  Pill,
} from 'lucide-react';

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
  { to: '/pos', icon: ShoppingCart, label: 'POS', roles: ['Super Admin', 'Cashier'] },
  { to: '/sales', icon: ClipboardList, label: 'Sales History', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
  { to: '/inventory', icon: Boxes, label: 'Inventory', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
  { to: '/products', icon: Tag, label: 'Products', roles: ['Super Admin', 'Stock Manager'] },
  { to: '/categories', icon: Tag, label: 'Categories', roles: ['Super Admin', 'Stock Manager'] },
  { to: '/suppliers', icon: Building, label: 'Suppliers', roles: ['Super Admin', 'Stock Manager'] },
  { to: '/purchase-orders', icon: Truck, label: 'Purchase Orders', roles: ['Super Admin', 'Stock Manager'] },
  { to: '/users', icon: Users, label: 'Users', roles: ['Super Admin'] },
  { to: '/settings', icon: Settings, label: 'Settings', roles: ['Super Admin'] },
];

const Sidebar: React.FC = () => {
  const { role } = useAuth();

  const activeLinkClass = 'bg-primary/10 text-primary';
  const inactiveLinkClass = 'text-secondary-foreground/70 hover:bg-primary/5 hover:text-primary';

  return (
    <aside className="hidden md:flex md:flex-col md:w-64 bg-secondary border-r">
      <div className="flex items-center h-16 border-b px-6">
        <Pill className="h-8 w-8 text-primary" />
        <h1 className="ml-3 text-xl font-bold text-secondary-foreground">B-Pharma POS</h1>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {navItems.map((item) =>
          role && item.roles.includes(role) ? (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                cn(
                  'flex items-center rounded-lg px-4 py-2.5 text-sm font-medium transition-colors',
                  isActive ? activeLinkClass : inactiveLinkClass
                )
              }
            >
              <item.icon className="mr-3 h-5 w-5" />
              <span>{item.label}</span>
            </NavLink>
          ) : null
        )}
      </nav>
    </aside>
  );
};

export default Sidebar;
