// import type { Bucket, S3Object, BucketContentsResponse, ObjectDetails } from '@/types/api';
import { ROLES } from '@/lib/authorization';
import type { Site, User } from '@/types/api';

const SITE_DEFAULTS: Site = {
  id: 0,
  title: 'DLC Subsite',
  alternativeTitle: 'DLC Subsite Alternative Title',
  slug: 'dlc_subsite',
  persistentUrl: 'persistent_url',
  layout: 'default',
  palette: 'default',
  searchType: 'basic',
  restricted: false,
  permissions: [],
  mapSearch: false,
  dateSearch: false,
  bannerImageUrl: '',
  watermarkImageUrl: '',
  hasBannerImage: false,
  hasWatermarkImage: false,
  updatedAt: new Date().toISOString(),
  showFacets: true,
  searchConfiguration: {
    exampleConfigKey: 'exampleConfigValue',
  },
  imageUris: [],
  publisherUri: 'publisher_uri',
  repositoryId: 'repository_id',
}

export const buildSite = (overrides?: Partial<Site>): Site => ({
  ...SITE_DEFAULTS,
  ...overrides,
});

export const buildSitesList = (count = 5, overrides?: Partial<Site>): Site[] => {
  return Array.from({ length: count }, (_, index) => buildSite({
    id: index + 1,
    slug: `dlc_subsite_${index + 1}`,
    ...overrides,
  }));
};

const USER_DEFAULTS: User = {
  uid: 'ta123',
  firstName: 'Admin',
  lastName: 'User',
  email: 'ta123@columbia.edu',
  permissions: {
    role: ROLES.ADMIN,
    canEdit: null,
  },
};

export const buildUser = (overrides?: Partial<User>): User => ({
  ...USER_DEFAULTS,
  ...overrides, 
});
