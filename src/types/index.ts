export type UserRole = 'Super Admin' | 'Stock Manager' | 'Cashier';

export interface Profile {
  id: string;
  first_name: string | null;
  last_name: string | null;
  role: UserRole;
  avatar_url: string | null;
}

export interface Sale {
  id: string;
  created_at: string;
  total_amount: number;
  profiles: {
    first_name: string | null;
    last_name: string | null;
  } | null;
}
