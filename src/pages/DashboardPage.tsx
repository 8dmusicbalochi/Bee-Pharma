import React, { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/useAuth';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/Button';
import { DollarSign, Package, PackagePlus, PlusCircle, AlertTriangle } from 'lucide-react';
import { Link } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import { Sale } from '@/types';

interface DashboardStats {
  totalSalesToday: number;
  lowStockItems: number;
  pendingOrders: number;
}

const StatCardSkeleton: React.FC = () => (
  <div className="bg-secondary rounded-xl shadow p-6 flex items-center gap-4 animate-pulse">
    <div className="rounded-full bg-gray-200 h-12 w-12"></div>
    <div className="flex-1 space-y-2">
      <div className="h-4 bg-gray-200 rounded w-3/4"></div>
      <div className="h-6 bg-gray-200 rounded w-1/2"></div>
    </div>
  </div>
);

const StatCard: React.FC<{ title: string; value: string; icon: React.ElementType; color: string }> = ({ title, value, icon: Icon, color }) => (
  <motion.div 
    className="bg-secondary rounded-xl shadow p-6 flex items-center gap-4"
    whileHover={{ scale: 1.03 }}
    transition={{ type: 'spring', stiffness: 300 }}
  >
    <div className={`rounded-full p-3`} style={{ backgroundColor: `${color}20`}}>
      <Icon className="h-6 w-6" style={{ color }} />
    </div>
    <div>
      <p className="text-sm text-secondary-foreground/70">{title}</p>
      <p className="text-2xl font-bold text-secondary-foreground">{value}</p>
    </div>
  </motion.div>
);

const QuickActionButton: React.FC<{ to: string; label: string; icon: React.ElementType }> = ({ to, label, icon: Icon }) => (
    <Link to={to}>
        <Button variant="outline" className="w-full h-24 flex flex-col items-center justify-center gap-2 text-base">
            <Icon className="h-7 w-7 text-primary" />
            <span>{label}</span>
        </Button>
    </Link>
);

const DashboardPage: React.FC = () => {
  const { profile } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [recentSales, setRecentSales] = useState<Sale[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      setLoading(true);
      setError(null);
      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const [salesRes, productsRes, ordersRes, recentSalesRes] = await Promise.all([
          supabase
            .from('sales')
            .select('total_amount', { count: 'exact' })
            .gte('created_at', today.toISOString())
            .lt('created_at', tomorrow.toISOString()),
          supabase
            .from('products')
            .select('id', { count: 'exact' })
            .lte('stock_quantity', 0), // Simplified for now, should compare with low_stock_threshold
          supabase
            .from('purchase_orders')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'Pending'),
          supabase
            .from('sales')
            .select('id, created_at, total_amount, profiles:customer_id(first_name, last_name)')
            .order('created_at', { ascending: false })
            .limit(5)
        ]);
        
        if (salesRes.error || productsRes.error || ordersRes.error || recentSalesRes.error) {
            console.error('Sales Error:', salesRes.error);
            console.error('Products Error:', productsRes.error);
            console.error('Orders Error:', ordersRes.error);
            console.error('Recent Sales Error:', recentSalesRes.error);
            throw new Error('Failed to fetch dashboard data. Please check console for details.');
        }

        const totalSalesToday = salesRes.data?.reduce((sum, sale) => sum + sale.total_amount, 0) || 0;
        const lowStockItems = productsRes.count || 0;
        const pendingOrders = ordersRes.count || 0;

        setStats({ totalSalesToday, lowStockItems, pendingOrders });
        setRecentSales(recentSalesRes.data as Sale[]);

      } catch (err: any) {
        setError(err.message);
        console.error("Error fetching dashboard data:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-6"
    >
      <div>
        <h1 className="text-3xl font-bold text-gray-900">
          Welcome back, {profile?.first_name || 'User'}!
        </h1>
        <p className="text-gray-600">Here's a summary of your pharmacy's activity today.</p>
      </div>
      
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative flex items-center" role="alert">
            <AlertTriangle className="h-5 w-5 mr-2" />
            <span className="block sm:inline">{error}</span>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
            <>
                <StatCardSkeleton />
                <StatCardSkeleton />
                <StatCardSkeleton />
            </>
        ) : stats ? (
            <>
                <StatCard title="Today's Sales" value={new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(stats.totalSalesToday)} icon={DollarSign} color="#2563EB" />
                <StatCard title="Low Stock Items" value={stats.lowStockItems.toString()} icon={Package} color="#F59E0B" />
                <StatCard title="Pending Orders" value={stats.pendingOrders.toString()} icon={PackagePlus} color="#10B981" />
            </>
        ) : null}
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <QuickActionButton to="/pos" label="New Sale" icon={PlusCircle} />
            <QuickActionButton to="/inventory" label="Receive Stock" icon={PackagePlus} />
            <QuickActionButton to="/products" label="Add Product" icon={PlusCircle} />
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="bg-secondary rounded-xl shadow p-6">
        <h2 className="text-xl font-semibold mb-4">Recent Transactions</h2>
        <div className="space-y-4">
          {loading ? (
            Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="flex justify-between items-center animate-pulse">
                    <div className="space-y-2">
                        <div className="h-4 bg-gray-200 rounded w-24"></div>
                        <div className="h-3 bg-gray-200 rounded w-32"></div>
                    </div>
                    <div className="h-6 bg-gray-200 rounded w-20"></div>
                </div>
            ))
          ) : recentSales && recentSales.length > 0 ? (
            recentSales.map(sale => (
                <div key={sale.id} className="flex justify-between items-center border-b pb-2 last:border-b-0">
                    <div>
                        <p className="font-medium text-secondary-foreground">
                            {sale.profiles ? `${sale.profiles.first_name || ''} ${sale.profiles.last_name || ''}`.trim() : 'Walk-in Customer'}
                        </p>
                        <p className="text-sm text-gray-500">{new Date(sale.created_at).toLocaleString()}</p>
                    </div>
                    <p className="font-bold text-lg text-secondary-foreground">
                        {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(sale.total_amount)}
                    </p>
                </div>
            ))
          ) : (
            <div className="text-center py-8 text-gray-500">
                <p>No recent transactions found.</p>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  );
};

export default DashboardPage;
