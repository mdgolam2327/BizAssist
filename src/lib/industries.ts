import { Apple, Shirt, Smartphone, BriefcaseMedical, Utensils, Boxes, Hammer, ShoppingBag, Truck, type LucideIcon } from 'lucide-react';

export type Industry = { key: string; name: string; description: string; icon: LucideIcon; modules: string[] };
export const industries: Industry[] = [
  { key: 'grocery', name: 'Grocery store', description: 'Fresh stock, fast checkout and expiry tracking.', icon: Apple, modules: ['Barcode', 'Low stock alerts', 'Fast-moving products', 'Expiry tracking'] },
  { key: 'clothing', name: 'Clothing & fashion', description: 'Manage sizes, colors, collections and seasons.', icon: Shirt, modules: ['Size variants', 'Color variants', 'Brands & collections', 'Seasonal inventory'] },
  { key: 'electronics', name: 'Electronics', description: 'Track serial numbers, warranty and repairs.', icon: Smartphone, modules: ['IMEI & serial numbers', 'Warranty tracking', 'Repair records', 'Product models'] },
  { key: 'pharmacy', name: 'Pharmacy', description: 'Keep batch and expiry details close at hand.', icon: BriefcaseMedical, modules: ['Medicine batches', 'Expiry management', 'Batch-level stock', 'Prescription records'] },
  { key: 'restaurant', name: 'Restaurant', description: 'Connect menus, tables, recipes and orders.', icon: Utensils, modules: ['Food menu', 'Table management', 'Kitchen display', 'Recipes & ingredients'] },
  { key: 'wholesale', name: 'Wholesale business', description: 'Make bulk orders and customer pricing easier.', icon: Boxes, modules: ['Bulk orders', 'Wholesale price tiers', 'Credit limits', 'Bulk inventory'] },
  { key: 'hardware', name: 'Hardware store', description: 'Sell by weight, length, volume or piece.', icon: Hammer, modules: ['Measurement-based products', 'Flexible units', 'Specifications', 'Bulk stock'] },
  { key: 'ecommerce', name: 'Online / e-commerce', description: 'Bring orders, shipping and returns together.', icon: ShoppingBag, modules: ['Online orders', 'Shipping & fulfillment', 'Returns & refunds', 'Sales channels'] },
  { key: 'distribution', name: 'Distributor & wholesaler', description: 'Coordinate dealers, territories and delivery.', icon: Truck, modules: ['Dealer management', 'Territories', 'Sales representatives', 'Routes & transfers'] },
];

export const commonModules = ['Dashboard', 'Customers', 'Suppliers', 'Products', 'Inventory', 'Sales', 'Purchases', 'Payments', 'Accounting', 'Expenses', 'Invoices', 'Reports', 'Employees', 'Notifications', 'Settings'];
