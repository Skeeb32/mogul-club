import { Controller, Get, Injectable, NotFoundException, Param, Query, ServiceUnavailableException } from '@nestjs/common';
import { ApiOkResponse, ApiProperty, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';
import { Type } from 'class-transformer';
import type { Property, PropertyPage } from '@mogul/contracts';
import { Database } from './database';
import { Public } from './security';
import { loadConfig } from './config';
export class PropertyQuery {
  @IsOptional() @IsString() @MaxLength(80) q?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(10000) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) limit = 20;
}
export class PropertyResponse implements Property {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() city!: string;
  @ApiProperty() state!: string;
  @ApiProperty({ enum: ['Single family', 'Townhome'] }) propertyType!: Property['propertyType'];
  @ApiProperty() bedrooms!: number;
  @ApiProperty() bathrooms!: number;
  @ApiProperty() areaSqFt!: number;
  @ApiProperty({ type: 'integer', description: 'Illustrative USD cents, not a verified valuation' }) illustrativeValueMinor!: number;
  @ApiProperty({ enum: ['USD'] }) currency!: 'USD';
  @ApiProperty() summary!: string;
  @ApiProperty({ enum: [true] }) synthetic!: true;
  @ApiProperty({ enum: ['demo_only'] }) status!: 'demo_only';
  @ApiProperty() source!: string;
  @ApiProperty({ format: 'date-time' }) updatedAt!: string;
}
export class PageResponse implements PropertyPage {
  @ApiProperty({ type: [PropertyResponse] }) items!: Property[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
  @ApiProperty({ enum: ['demo'] }) mode!: 'demo';
}
@Injectable()
export class PropertiesService {
  constructor(private readonly database: Database) {}
  private assertDemo() {
    const config = loadConfig();
    if (!config.demo || config.environment === 'production') throw new NotFoundException('Resource unavailable');
  }
  async list(query: PropertyQuery): Promise<PropertyPage> {
    this.assertDemo();
    const text = query.q?.trim();
    const escaped = text?.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const filter = { synthetic: true as const, status: 'demo_only' as const,
      ...(escaped ? { $or: ['name', 'city', 'state'].map(field => ({ [field]: { $regex: escaped, $options: 'i' } })) } : {}) };
    try {
      const [items, total] = await Promise.all([
        this.database.properties.find(filter, { projection: { _id: 0 } }).sort({ id: 1 }).skip((query.page - 1) * query.limit).limit(query.limit).toArray(),
        this.database.properties.countDocuments(filter),
      ]);
      return { items, total, page: query.page, limit: query.limit, mode: 'demo' };
    } catch { throw new ServiceUnavailableException('Property service unavailable'); }
  }
  async detail(id: string): Promise<Property> {
    this.assertDemo();
    if (!/^[a-z0-9-]{1,80}$/.test(id)) throw new NotFoundException('Property not found');
    let property: Property | null;
    try { property = await this.database.properties.findOne({ id, synthetic: true, status: 'demo_only' }, { projection: { _id: 0 } }); }
    catch { throw new ServiceUnavailableException('Property service unavailable'); }
    if (!property) throw new NotFoundException('Property not found');
    return property;
  }
}
@ApiTags('Demo properties')
@ApiResponse({ status: 400, description: 'Invalid or unknown query parameters' })
@ApiResponse({ status: 429, description: 'Rate limit exceeded' })
@ApiResponse({ status: 404, description: 'Missing record or demo disabled' })
@ApiResponse({ status: 503, description: 'Storage unavailable' })
@Public()
@Controller('properties')
export class PropertiesController {
  constructor(private readonly service: PropertiesService) {}
  @Get() @ApiOkResponse({ type: PageResponse })
  @ApiQuery({ name: 'q', required: false, type: String })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  list(@Query() query: PropertyQuery) { return this.service.list(query); }
  @Get(':id') @ApiOkResponse({ type: PropertyResponse })
  detail(@Param('id') id: string) { return this.service.detail(id); }
}
