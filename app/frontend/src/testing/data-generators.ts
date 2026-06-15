// import type { Bucket, S3Object, BucketContentsResponse, ObjectDetails } from '@/types/api';
import { ROLES } from '@/lib/authorization';
import {
  type Site,
  type User,
  type SitePage,
  type NavGroup,
  type NavLink,
  SearchType,
  SitePalette,
  SiteLayout,
} from '@/types/api';

const SITE_DEFAULTS: Site = {
  id: 0,
  title: 'DLC Subsite',
  alternativeTitle: 'DLC Subsite Alternative Title',
  slug: 'dlc_subsite',
  persistentUrl: 'persistent_url',
  layout: SiteLayout.SIGNATURE,
  palette: SitePalette.DEFAULT,
  searchType: SearchType.CATALOG,
  restricted: false,
  permissions: [],
  mapSearch: false,
  dateSearch: false,
  bannerImageUrl: '/images/sites/dlc_subsite/signature-banner.png',
  watermarkImageUrl: '/assets/signature/signature/svg',
  hasBannerImage: true,
  hasWatermarkImage: false,
  updatedAt: new Date().toISOString(),
  showFacets: true,
  searchConfiguration: {
    exampleConfigKey: 'exampleConfigValue',
  },
  imageUris: ['uri1', 'uri2'],
  publisherUri: 'publisher_uri',
  repositoryId: 'repository_id',
};

export const buildSite = (overrides?: Partial<Site>): Site => ({
  ...SITE_DEFAULTS,
  ...overrides,
});

export const buildSitesList = (count = 5, overrides?: Partial<Site>): Site[] => {
  return Array.from({ length: count }, (_, index) =>
    buildSite({
      id: index + 1,
      slug: `dlc_subsite_${index + 1}`,
      ...overrides,
    }),
  );
};

const SITE_PAGE_DEFAULTS: SitePage = {
  siteSlug: 'dlc_subsite',
  pageSlug: 'home',
  title: 'Home Page',
  columns: 1,
  siteId: 0, // default Site id
  updatedAt: 'Wed, 25 Mar 2026 14:03:34.839737000 UTC +00:00,',
};

export const buildSitePage = (overrides?: Partial<SitePage>) => ({
  ...SITE_PAGE_DEFAULTS,
  ...overrides,
});

// N.B. this considers 'home' as the first page, therefore next page is 'page_2'
export const buildSitePages = (count = 2, overrides?: Partial<SitePage>) => {
  return Array.from({ length: count }, (_, index) => {
    const first = index === 0;
    return buildSitePage({
      pageSlug: first ? 'home' : `page_${index + 1}`,
      title: first ? 'Home Page' : `Page ${index + 1}`,
      ...overrides,
    });
  });
};

const NAV_LINK_DEFAULTS = {
  linkLabel: 'Link Label',
  linkValue: 'link',
  external: false,
  iconClass: null,
};

const NAV_GROUP_DEFAULTS: NavGroup = {
  groupLabel: 'Nav Group',
  childrenLinks: [NAV_LINK_DEFAULTS],
};

export const buildNavLink = (overrides?: Partial<NavLink>) => ({
  ...NAV_LINK_DEFAULTS,
  ...overrides,
});

export const buildNavLinks = (count = 2, overrides?: Partial<NavLink>) => {
  return Array.from({ length: count }, (_, index) =>
    buildNavLink({
      linkLabel: `Link ${index}`,
      linkValue: `link_${index}`,
      ...overrides,
    }),
  );
};

export const buildNavGroup = (overrides?: Partial<NavGroup>) => ({
  ...NAV_GROUP_DEFAULTS,
  ...overrides,
});

export const buildNavGroups = (count = 2, overrides?: Partial<NavGroup>) => {
  return Array.from({ length: count }, (_, index) =>
    buildNavGroup({
      groupLabel: `Nav Group ${index}`,
      childrenLinks: buildNavLinks(),
      ...overrides,
    }),
  );
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

import process from 'node:process';
import fs from 'node:fs';

// Temp banner image file creation and cleanup
export const createTempBannerImage = async (subsiteSlug = SITE_DEFAULTS.slug) => {
  try {
    const projectRoot = process.cwd();
    const dirPath = `${projectRoot}/public/images/sites/${subsiteSlug}`;
    const filePath = `${projectRoot}/public/images/sites/${subsiteSlug}/signature-banner.png`;
    fs.mkdirSync(dirPath, { recursive: true });
    fs.writeFileSync(filePath, 'image content');
  } catch (error) {
    console.log(error);
  }
};
export const deleteTempBannerImage = (subsiteSlug = SITE_DEFAULTS.slug) => {
  try {
    const projectRoot = process.cwd();
    const filePath = `${projectRoot}/public/images/sites/${subsiteSlug}/signature-banner.png`;
    const dirPath = `${projectRoot}/public/images/sites/${subsiteSlug}`;
    fs.rmSync(dirPath, { recursive: true });
  } catch (error) {
    console.log(error);
  }
};
