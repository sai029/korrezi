import React from 'react';
import { NavigationDrawer } from 'flutter-comic-tabloid-ds';

export function ChildActive() {
  return (
    <div style={{ height: 520, display: 'flex', border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <NavigationDrawer currentPath="/child" />
    </div>
  );
}

export function CommonActive() {
  return (
    <div style={{ height: 520, display: 'flex', border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <NavigationDrawer currentPath="/common" />
    </div>
  );
}

export function ParentActive() {
  return (
    <div style={{ height: 520, display: 'flex', border: '2.5px solid #000B29', borderRadius: 4, overflow: 'hidden' }}>
      <NavigationDrawer currentPath="/parent" />
    </div>
  );
}
