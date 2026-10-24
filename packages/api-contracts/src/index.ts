/** Read-only synthetic discovery contract. Amounts are integer USD cents. */
export interface Property {
  id: string;
  name: string;
  city: string;
  state: string;
  propertyType: 'Single family' | 'Townhome';
  bedrooms: number;
  bathrooms: number;
  areaSqFt: number;
  illustrativeValueMinor: number;
  currency: 'USD';
  summary: string;
  synthetic: true;
  status: 'demo_only';
  source: string;
  updatedAt: string;
}
export interface PropertyPage {
  items: Property[];
  total: number;
  page: number;
  limit: number;
  mode: 'demo';
}
