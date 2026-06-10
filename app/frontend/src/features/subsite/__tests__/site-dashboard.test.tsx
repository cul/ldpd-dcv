import { describe, it, expect, beforeEach } from 'vitest';
import { buildSitesList, buildUser, mockApi, renderApp, within, screen, act } from '@/testing/test-utils';
import SitesDashboard from '@/features/sites/components/sites-dashboard';
import { ROLES } from '@/lib/authorization';

describe('SubsiteDashboard', () => {
  beforeEach(() => {
    mockApi('get', )
  });
})