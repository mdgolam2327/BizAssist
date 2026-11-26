export type BusinessRole='owner'|'manager'|'accountant'|'sales'|'inventory'|'delivery';
export type BusinessRecord={id:string;name:string;owner_name:string;business_type:string;currency:string;timezone:string;created_at:string};
export type BusinessModuleRecord={business_id:string;module_id:string;enabled:boolean;enabled_by:string|null};
