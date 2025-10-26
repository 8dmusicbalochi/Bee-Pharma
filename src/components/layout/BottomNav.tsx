import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  ShoppingCart,
  Boxes,
  Menu,
} from 'lucide-react';

const navItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
    { to: '/pos', icon: ShoppingCart, label: 'POS', roles: ['Super Admin', 'Cashier'] },
    { to: '/inventory', icon: Boxes, label: 'Inventory', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
    // A "More" button would typically open a side drawer or modal on mobile.
    // For now, we'll link it to a placeholder or a main menu page if we create one.
    // Let's link to settings for now as a placeholder for 'More'.
    { to: '/settings', icon: Menu, label: 'More', roles: ['Super Admin', 'Stock Manager', 'Cashier'] },
];

const BottomNav: React.FC = () => {
    const { role } = useAuth();
    const activeLinkClass = 'text-primary';
    const inactiveLinkClass = 'text-secondary-foreground/60';

    return (
        <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-secondary border-t z-20">
            <div className="flex justify-around items-center h-16">
                {navItems.map((item) =>
                    role && item.roles.includes(role) ? (
                        <NavLink
                            key={item.to}
                            to={item.to}
                            end={item.to === '/'}
                            className={({ isActive }) =>
                                cn(
                                    'flex flex-col items-center justify-center w-full transition-colors',
                                    isActive ? activeLinkClass : inactiveLinkClass
                                )
                            }
                        >
                            <item.icon className="h-6 w-6 mb-1" />
                            <span className="text-xs font-medium">{item.label}</span>
                        </NavLink>
                    ) : null
                )}
            </div>
        </nav>
    );
};

export default BottomNav;
