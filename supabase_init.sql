-- ======================================================================
-- SCRIPT SQL COMPLETO PARA SUPABASE - MiChaucherita
-- ======================================================================
-- INSTRUCCIONES:
-- 1. Ve a tu proyecto Supabase: https://esojxuaowcxvzsfutlzp.supabase.co
-- 2. Clic en "SQL Editor" en el menú izquierdo
-- 3. Clic en "New Query"
-- 4. COPIA Y PEGA TODO ESTE ARCHIVO
-- 5. Clic en "RUN" (botón verde abajo a la derecha)
-- 6. Verifica en "Table Editor" que se crearon las tablas
-- ======================================================================

-- =======================
-- TABLA: accounts
-- Cuentas bancarias del usuario
-- =======================
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('bank', 'cash', 'credit', 'savings', 'investment')),
  balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
  currency TEXT NOT NULL DEFAULT 'PEN',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(is_active) WHERE is_active = true;

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_accounts_updated_at ON accounts;
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =======================
-- TABLA: categories
-- Categorías de transacciones
-- =======================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  icon TEXT,
  color TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_active ON categories(is_active) WHERE is_active = true;

-- =======================
-- TABLA: transactions
-- Transacciones (ingresos/gastos)
-- =======================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  description TEXT,
  date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ======================================================================
-- CONFIGURAR ROW LEVEL SECURITY (RLS)
-- ======================================================================
-- IMPORTANTE: Esto asegura que cada usuario solo vea sus propios datos.

-- Habilitar RLS en las tablas
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- =======================
-- POLÍTICAS PARA ACCOUNTS
-- =======================

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can insert own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can update own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can delete own accounts" ON accounts;

-- Política de lectura: usuarios ven solo sus cuentas
CREATE POLICY "Users can view own accounts"
  ON accounts FOR SELECT
  USING (auth.uid() = user_id);

-- Política de inserción: usuarios crean solo sus cuentas
CREATE POLICY "Users can insert own accounts"
  ON accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política de actualización: usuarios actualizan solo sus cuentas
CREATE POLICY "Users can update own accounts"
  ON accounts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Política de eliminación: usuarios eliminan solo sus cuentas
CREATE POLICY "Users can delete own accounts"
  ON accounts FOR DELETE
  USING (auth.uid() = user_id);

-- =======================
-- POLÍTICAS PARA TRANSACTIONS
-- =======================

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

-- Política de lectura: usuarios ven solo sus transacciones
CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Política de inserción: usuarios crean solo sus transacciones
CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política de actualización: usuarios actualizan solo sus transacciones
CREATE POLICY "Users can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Política de eliminación: usuarios eliminan solo sus transacciones
CREATE POLICY "Users can delete own transactions"
  ON transactions FOR DELETE
  USING (auth.uid() = user_id);

-- =======================
-- POLÍTICAS PARA CATEGORIES
-- =======================

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Everyone can view categories" ON categories;

-- Las categorías por defecto son públicas (visibles para todos)
CREATE POLICY "Everyone can view categories"
  ON categories FOR SELECT
  USING (is_default = true);

-- ======================================================================
-- INSERTAR CATEGORÍAS POR DEFECTO
-- ======================================================================

-- Categorías de GASTOS
INSERT INTO categories (name, type, icon, color, is_default) VALUES
  ('Alimentos', 'expense', 'restaurant', '#FF6B6B', true),
  ('Transporte', 'expense', 'directions_car', '#4ECDC4', true),
  ('Vivienda', 'expense', 'home', '#45B7D1', true),
  ('Servicios', 'expense', 'receipt_long', '#FFA07A', true),
  ('Salud', 'expense', 'local_hospital', '#98D8C8', true),
  ('Entretenimiento', 'expense', 'movie', '#F7DC6F', true),
  ('Educación', 'expense', 'school', '#BB8FCE', true),
  ('Compras', 'expense', 'shopping_bag', '#F8B500', true),
  ('Ropa', 'expense', 'checkroom', '#EC7063', true),
  ('Otros Gastos', 'expense', 'more_horiz', '#95A5A6', true)
ON CONFLICT DO NOTHING;

-- Categorías de INGRESOS
INSERT INTO categories (name, type, icon, color, is_default) VALUES
  ('Salario', 'income', 'payments', '#27AE60', true),
  ('Freelance', 'income', 'work', '#3498DB', true),
  ('Inversiones', 'income', 'trending_up', '#9B59B6', true),
  ('Ventas', 'income', 'store', '#E67E22', true),
  ('Otros Ingresos', 'income', 'attach_money', '#16A085', true)
ON CONFLICT DO NOTHING;

-- ======================================================================
-- VERIFICACIÓN
-- ======================================================================

-- Verificar que las tablas se crearon correctamente
SELECT 
  'Tablas creadas:' as status,
  COUNT(*) as total
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('accounts', 'categories', 'transactions');

-- Verificar políticas RLS
SELECT 
  'Políticas RLS configuradas:' as status,
  COUNT(*) as total
FROM pg_policies 
WHERE schemaname = 'public';

-- Contar categorías por defecto
SELECT 
  'Categorías por tipo:' as status,
  type, 
  COUNT(*) as total
FROM categories 
WHERE is_default = true 
GROUP BY type;

-- ======================================================================
-- ¡LISTO! Si ves resultados arriba, todo funcionó correctamente.
-- ======================================================================
