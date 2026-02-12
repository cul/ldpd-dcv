import * as React from 'react';
import { AppRouter } from '@/app/router';
import AppProvider from '@/app/provider';

const App = () => {
  return (
    <React.StrictMode>
      <AppProvider>
        <AppRouter />
      </AppProvider>
    </React.StrictMode>
  )
}

export default App;