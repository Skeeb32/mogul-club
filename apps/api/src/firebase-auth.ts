import { Injectable } from '@nestjs/common';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { DecodedIdToken, getAuth } from 'firebase-admin/auth';
import { loadConfig } from './config';

@Injectable()
export class FirebaseAuthVerifier {
  private readonly auth = this.createAuth();
  private createAuth() {
    const projectId = loadConfig().firebaseProjectId;
    if (!projectId) return undefined;
    const app = getApps().find(candidate => candidate.name === 'mogul-auth')
      ?? initializeApp({ credential: applicationDefault(), projectId }, 'mogul-auth');
    return getAuth(app);
  }
  async verify(token: string): Promise<DecodedIdToken | undefined> {
    if (!this.auth) return undefined;
    try { return await this.auth.verifyIdToken(token, true); }
    catch { return undefined; }
  }
}
