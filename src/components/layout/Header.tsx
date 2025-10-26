import React from 'react';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/Button';
import { LogOut, User as UserIcon, Settings } from 'lucide-react';
import { Link } from 'react-router-dom';

interface HeaderProps {
  title: string;
}

const Header: React.FC<HeaderProps> = ({ title }) => {
  const { profile, signOut } = useAuth();

  return (
    <header className="bg-secondary sticky top-0 z-10 flex h-16 items-center justify-between border-b px-4 md:px-6">
      <h1 className="text-xl font-semibold text-secondary-foreground">{title}</h1>
      <div className="flex items-center gap-4">
        {/* User Dropdown - simplified for now */}
        <div className="flex items-center gap-2">
          <div className="h-9 w-9 rounded-full bg-primary flex items-center justify-center text-primary-foreground font-bold">
            {profile?.first_name?.[0] || 'U'}
          </div>
          <div className="hidden md:block">
            <p className="text-sm font-medium">{profile?.first_name} {profile?.last_name}</p>
            <p className="text-xs text-gray-500">{profile?.role}</p>
          </div>
        </div>
        <Button onClick={signOut} variant="ghost" size="icon">
          <LogOut className="h-5 w-5" />
        </Button>
      </div>
    </header>
  );
};

export default Header;
