import { CanActivate, ExecutionContext, Injectable, SetMetadata, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { FirebaseAuthVerifier } from './firebase-auth';
export const Public = () => SetMetadata('public', true);
export interface AuthenticatedPrincipal { uid: string; email?: string; emailVerified: boolean; }
/** Verifies Firebase ID tokens and revocation on trusted API requests. Closed when Firebase is unconfigured. */
@Injectable()
export class DefaultDenyGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly firebase: FirebaseAuthVerifier) {}
  async canActivate(context: ExecutionContext) {
    if (this.reflector.getAllAndOverride<boolean>('public', [context.getHandler(), context.getClass()])) return true;
    const request = context.switchToHttp().getRequest<{ headers: Record<string, string | string[] | undefined>; user?: AuthenticatedPrincipal }>();
    const header = request.headers.authorization;
    const match = typeof header === 'string' ? /^Bearer ([^\s]+)$/i.exec(header) : null;
    if (!match) throw new UnauthorizedException('Authentication required');
    const decoded = await this.firebase.verify(match[1]);
    if (!decoded || decoded.email_verified !== true) throw new UnauthorizedException('A valid verified account is required');
    request.user = { uid: decoded.uid, email: decoded.email, emailVerified: decoded.email_verified };
    return true;
  }
}
