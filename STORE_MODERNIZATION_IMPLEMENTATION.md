# Store Modernization Implementation Guide

## TypeScript Interfaces Based on Current Store

### Core Data Types
```typescript
interface Item {
  id: number;
  code: string;
  index: number;
  tag_ids: number[];
  has_comments: boolean;
  // Add other properties as needed
}

interface ItemDetails {
  id: number;
  comments: Comment[];
  paths: string[];
  ages: Record<string, any>;
}

interface Tag {
  id: number;
  label: string;
  alias?: string;
  icon_id?: number;
  icon_code?: string;
  icon_item_id?: number;
  item_count: number;
}

interface Comment {
  id: number;
  text: string;
  item_id: number;
  user_id: number;
  user?: User;
  created_at: string;
}

interface User {
  id: number;
  name: string;
  email: string;
}

interface Activity {
  id: number;
  comment?: Comment;
  bullhorn?: any;
  tagging?: any;
}

interface TagMatch {
  match?: Tag;
  miss?: string;
  current?: boolean;
}
```

### API Wrapper Implementation
```typescript
// lib/api.ts
interface ApiResponse<T> {
  data: T;
  meta?: {
    total: number;
    search_key: string;
    index: number;
  };
}

class ApiClient {
  private baseURL = '/api';
  private csrfToken: string;

  constructor() {
    this.csrfToken = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || '';
  }

  async request<T>(
    url: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const response = await fetch(`${this.baseURL}${url}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API Error: ${response.status} ${error}`);
    }

    return response.json();
  }

  get<T>(url: string): Promise<ApiResponse<T>> {
    return this.request<T>(url);
  }

  post<T>(url: string, data: any): Promise<ApiResponse<T>> {
    return this.request<T>(url, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  put<T>(url: string, data: any): Promise<ApiResponse<T>> {
    return this.request<T>(url, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  delete<T>(url: string): Promise<ApiResponse<T>> {
    return this.request<T>(url, {
      method: 'DELETE',
    });
  }
}

export const api = new ApiClient();
```

### Context Implementations

#### ItemsContext Implementation
```typescript
// contexts/ItemsContext.tsx
import React, { createContext, useContext, useReducer, useCallback } from 'react';
import { api } from '../lib/api';

interface ItemsState {
  items: Record<number, number>; // index -> itemId
  itemsById: Record<number, Item>;
  details: Record<number, ItemDetails>;
  resultCount: number | null;
  searchKey: string | null;
  searching: boolean;
  loading: boolean;
  error: string | null;
}

interface ItemsActions {
  fetchItem: (itemId: number) => Promise<Item | null>;
  fetchItemDetails: (itemId: number, force?: boolean) => Promise<ItemDetails>;
  executeSearch: (start: number, end: number, query: string) => Promise<void>;
  updateItems: (items: Item[]) => void;
  clearItems: () => void;
  rateItem: (itemId: number, rating: number) => Promise<void>;
  toggleItemStar: (itemId: number) => Promise<void>;
  toggleItemBullhorn: (itemId: number) => Promise<void>;
}

type ItemsContextType = ItemsState & ItemsActions;

const ItemsContext = createContext<ItemsContextType | null>(null);

// Actions
type ItemsAction = 
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_SEARCHING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_ITEMS'; payload: { items: Record<number, number>; itemsById: Record<number, Item> } }
  | { type: 'SET_ITEM'; payload: Item }
  | { type: 'SET_DETAILS'; payload: { itemId: number; details: ItemDetails } }
  | { type: 'SET_RESULT_COUNT'; payload: number | null }
  | { type: 'SET_SEARCH_KEY'; payload: string | null }
  | { type: 'CLEAR_ITEMS' };

// Reducer
function itemsReducer(state: ItemsState, action: ItemsAction): ItemsState {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, loading: action.payload };
    case 'SET_SEARCHING':
      return { ...state, searching: action.payload };
    case 'SET_ERROR':
      return { ...state, error: action.payload };
    case 'SET_ITEMS':
      return { 
        ...state, 
        items: action.payload.items,
        itemsById: action.payload.itemsById,
      };
    case 'SET_ITEM':
      return {
        ...state,
        itemsById: {
          ...state.itemsById,
          [action.payload.id]: action.payload,
        },
      };
    case 'SET_DETAILS':
      return {
        ...state,
        details: {
          ...state.details,
          [action.payload.itemId]: action.payload.details,
        },
      };
    case 'SET_RESULT_COUNT':
      return { ...state, resultCount: action.payload };
    case 'SET_SEARCH_KEY':
      return { ...state, searchKey: action.payload };
    case 'CLEAR_ITEMS':
      return {
        ...state,
        items: {},
        itemsById: {},
        details: {},
        resultCount: null,
        searchKey: null,
      };
    default:
      return state;
  }
}

// Provider
export const ItemsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(itemsReducer, {
    items: {},
    itemsById: {},
    details: {},
    resultCount: null,
    searchKey: null,
    searching: false,
    loading: false,
    error: null,
  });

  const fetchItem = useCallback(async (itemId: number): Promise<Item | null> => {
    const existingItem = state.itemsById[itemId];
    if (existingItem) return existingItem;
    
    if (state.loading) return null;

    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const response = await api.get<{ item: Item; meta: { index: number } }>(`/items/${itemId}`);
      
      const item = { ...response.data.item, index: response.data.meta.index };
      dispatch({ type: 'SET_ITEM', payload: item });
      
      return item;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Failed to fetch item' });
      return null;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }, [state.itemsById, state.loading]);

  const fetchItemDetails = useCallback(async (itemId: number, force = false): Promise<ItemDetails> => {
    const existingDetails = state.details[itemId];
    if (existingDetails && !force) return existingDetails;

    const blankDetails: ItemDetails = { id: itemId, comments: [], paths: [], ages: {} };
    
    if (state.loading) return blankDetails;

    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      const response = await api.get<{ item: ItemDetails }>(`/items/${itemId}/details`);
      
      dispatch({ type: 'SET_DETAILS', payload: { itemId, details: response.data.item } });
      return response.data.item;
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Failed to fetch details' });
      return blankDetails;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  }, [state.details, state.loading]);

  const executeSearch = useCallback(async (start: number, end: number, query: string) => {
    if (state.searching) return;
    if (state.resultCount === 0) return;

    const batchSize = 100;
    const batchStart = start - (start % batchSize);
    const batchEnd = Math.min(end - (end % batchSize) + batchSize - 1, (state.resultCount || Infinity) - 1);

    // Check if we already have the data
    let missing = false;
    for (let i = batchStart; i <= batchEnd; i++) {
      if (!state.items[i]) {
        missing = true;
        break;
      }
    }

    if (!missing) return;

    try {
      dispatch({ type: 'SET_SEARCHING', payload: true });
      
      const response = await api.get<{ items: Item[]; meta: { total: number; search_key: string } }>('/items', {
        params: {
          limit: batchEnd - batchStart + 1,
          offset: batchStart,
          query: JSON.stringify({ query }), // Simplified - you'd parse this properly
          search_key: state.searchKey,
        },
      });

      const newItems: Record<number, number> = {};
      const newItemsById: Record<number, Item> = {};

      response.data.items.forEach((item, index) => {
        const itemIndex = batchStart + index;
        item.index = itemIndex;
        newItems[itemIndex] = item.id;
        newItemsById[item.id] = item;
      });

      dispatch({ type: 'SET_ITEMS', payload: { items: { ...state.items, ...newItems }, itemsById: { ...state.itemsById, ...newItemsById } } });
      dispatch({ type: 'SET_RESULT_COUNT', payload: response.data.meta.total });
      dispatch({ type: 'SET_SEARCH_KEY', payload: response.data.meta.search_key });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Search failed' });
    } finally {
      dispatch({ type: 'SET_SEARCHING', payload: false });
    }
  }, [state.searching, state.resultCount, state.items, state.itemsById, state.searchKey]);

  const rateItem = useCallback(async (itemId: number, rating: number) => {
    try {
      const response = await api.post<{ item: Item }>(`/items/${itemId}/rate`, { value: rating });
      dispatch({ type: 'SET_ITEM', payload: response.data.item });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Failed to rate item' });
    }
  }, []);

  const toggleItemStar = useCallback(async (itemId: number) => {
    try {
      const response = await api.post<{ item: Item }>(`/items/${itemId}/toggle_star`);
      dispatch({ type: 'SET_ITEM', payload: response.data.item });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Failed to toggle star' });
    }
  }, []);

  const toggleItemBullhorn = useCallback(async (itemId: number) => {
    try {
      const response = await api.post<{ item: Item }>(`/items/${itemId}/toggle_bullhorn`);
      dispatch({ type: 'SET_ITEM', payload: response.data.item });
    } catch (error) {
      dispatch({ type: 'SET_ERROR', payload: error instanceof Error ? error.message : 'Failed to toggle bullhorn' });
    }
  }, []);

  const updateItems = useCallback((items: Item[]) => {
    const newItemsById = { ...state.itemsById };
    items.forEach(item => {
      newItemsById[item.id] = item;
    });
    dispatch({ type: 'SET_ITEMS', payload: { items: state.items, itemsById: newItemsById } });
  }, [state.items, state.itemsById]);

  const clearItems = useCallback(() => {
    dispatch({ type: 'CLEAR_ITEMS' });
  }, []);

  const value: ItemsContextType = {
    ...state,
    fetchItem,
    fetchItemDetails,
    executeSearch,
    updateItems,
    clearItems,
    rateItem,
    toggleItemStar,
    toggleItemBullhorn,
  };

  return <ItemsContext.Provider value={value}>{children}</ItemsContext.Provider>;
};

export const useItems = () => {
  const context = useContext(ItemsContext);
  if (!context) {
    throw new Error('useItems must be used within an ItemsProvider');
  }
  return context;
};
```

### Migration Pattern Example

#### Before (CoffeeScript Component)
```coffeescript
# selectbar.coffee
component 'SelectBar', ({fixed}) ->
  selectedTags = ->
    index = {}
    tags = []
    for id of Store.state.selection
      item = Store.getItem id
      if !item
        console.warn "Can't find item #{id}"
        continue
      for tag_id in item.tag_ids
        obj = index[tag_id]
        if !obj
          tag = Store.state.tagsById[tag_id]
          if !tag
            console.warn "Can't find tag #{tag_id}"
            continue
          obj = index[tag_id] =
            tag: tag
            count: 0
          tags.push obj
        obj.count++
    tags

  addNewTags = (e) ->
    e.preventDefault()
    matches = []
    for part in Store.state.pendingTags
      matches.push part.match if part.match?
    
    if matches.length > 0
      Store.addTagsToSelection matches
    Store.clearSelection()
```

#### After (TypeScript Component)
```typescript
// SelectBar.tsx
import React, { useMemo } from 'react';
import { useSelection } from '../contexts/SelectionContext';
import { useItems } from '../contexts/ItemsContext';
import { useTags } from '../contexts/TagsContext';

interface SelectBarProps {
  fixed?: boolean;
}

const SelectBar: React.FC<SelectBarProps> = ({ fixed }) => {
  const { 
    selection, 
    selectionCount, 
    pendingTags, 
    clearSelection,
    addTagsToSelection 
  } = useSelection();
  
  const { itemsById } = useItems();
  const { tagsById } = useTags();

  const selectedTags = useMemo(() => {
    const index: Record<number, { tag: Tag; count: number }> = {};
    const tags: { tag: Tag; count: number }[] = [];

    Object.keys(selection).forEach(id => {
      const itemId = parseInt(id);
      const item = itemsById[itemId];
      
      if (!item) {
        console.warn(`Can't find item ${itemId}`);
        return;
      }

      item.tag_ids.forEach(tagId => {
        if (!index[tagId]) {
          const tag = tagsById[tagId];
          if (!tag) {
            console.warn(`Can't find tag ${tagId}`);
            return;
          }
          
          index[tagId] = { tag, count: 0 };
          tags.push(index[tagId]);
        }
        index[tagId].count++;
      });
    });

    return tags;
  }, [selection, itemsById, tagsById]);

  const handleAddTags = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const matches = pendingTags
      .map(part => part.match)
      .filter((match): match is Tag => match !== undefined);
    
    if (matches.length > 0) {
      await addTagsToSelection(matches);
    }
    
    clearSelection();
  };

  return (
    <div className="select-bar">
      <span className="selection-count">{selectionCount.toLocaleString()}</span>
      
      <form onSubmit={handleAddTags}>
        <input
          type="text"
          placeholder="Add tags"
          className="form-control"
          autoFocus
        />
      </form>
      
      <div className="selected-tags">
        {selectedTags.map(({ tag, count }) => (
          <TagIcon key={tag.id} tag={tag} count={count} />
        ))}
      </div>
    </div>
  );
};

export default SelectBar;
```

### Custom Hook Examples

#### useResizedURL Hook
```typescript
// hooks/useResizedURL.ts
import { useCallback } from 'react';

interface ItemRef {
  id: number;
  code?: string;
}

export const useResizedURL = () => {
  const getResizedURL = useCallback((size: string, item: ItemRef): string => {
    const ext = size === 'stream' ? 'mp4' : 'jpg';
    
    if (item.id === null) {
      return '/images/unknown-icon.png';
    }

    const filename = item.code 
      ? `${item.id}-${item.code}` 
      : `${item.id}`;
    
    return `/data/resized/${size}/${filename}.${ext}`;
  }, []);

  return { getResizedURL };
};
```

#### useComments Hook
```typescript
// hooks/useComments.ts
import { useState, useCallback } from 'react';
import { api } from '../lib/api';

export const useComments = (itemId: number) => {
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const addComment = useCallback(async (text: string) => {
    if (!text.trim()) return;

    try {
      setLoading(true);
      const response = await api.post<{ comment: Comment; users: User[] }>('/comments', {
        'comment[item_id]': itemId,
        'comment[text]': text,
      });

      const newComment = {
        ...response.data.comment,
        user: response.data.users[0],
      };

      setComments(prev => [...prev, newComment]);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add comment');
    } finally {
      setLoading(false);
    }
  }, [itemId]);

  return {
    comments,
    loading,
    error,
    addComment,
  };
};
```

### Testing Strategy

#### Context Testing Example
```typescript
// __tests__/ItemsContext.test.tsx
import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { ItemsProvider, useItems } from '../contexts/ItemsContext';
import { api } from '../lib/api';

// Mock the API
jest.mock('../lib/api');
const mockApi = api as jest.Mocked<typeof api>;

const TestComponent = () => {
  const { items, fetchItem } = useItems();
  
  return (
    <div>
      <button onClick={() => fetchItem(1)}>Fetch Item</button>
      <div data-testid="items-count">{Object.keys(items).length}</div>
    </div>
  );
};

describe('ItemsContext', () => {
  it('should fetch item correctly', async () => {
    const mockItem = { id: 1, code: 'test', index: 0, tag_ids: [] };
    mockApi.get.mockResolvedValue({ data: { item: mockItem, meta: { index: 0 } } });

    render(
      <ItemsProvider>
        <TestComponent />
      </ItemsProvider>
    );

    const fetchButton = screen.getByText('Fetch Item');
    fetchButton.click();

    await waitFor(() => {
      expect(screen.getByTestId('items-count')).toHaveTextContent('1');
    });

    expect(mockApi.get).toHaveBeenCalledWith('/items/1');
  });
});
```

This implementation guide provides concrete examples of how to migrate from your current CoffeeScript Store to a modern TypeScript React Context architecture. The key is to maintain the same functionality while improving the code structure and type safety.