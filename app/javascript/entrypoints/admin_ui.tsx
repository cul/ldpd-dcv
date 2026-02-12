// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'


import React from 'react';
import { createRoot } from 'react-dom/client';
import AdminApp from '../../frontend/src/app/AdminApp';
import App from '../../frontend/src/app/App';

const adminAppElement = document.getElementById('dlc-admin-app');
if (!adminAppElement) throw new Error('Admin app root element not found');

const adminRoot = createRoot(adminAppElement);
// adminRoot.render(<AdminApp />);
adminRoot.render(<App />)

console.log('Admin React app load complete!');
