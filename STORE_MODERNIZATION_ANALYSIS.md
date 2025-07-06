# Store Modernization Analysis & Implementation Plan

## Current State Analysis

### Existing Architecture Issues

Your current `Store` class (~550 lines) is a classic example of a monolithic state manager with several architectural problems:

1. **Mixed Responsibilities**: The Store handles:
   - State management (items, tags, selection, UI state)
   - Data fetching and AJAX calls
   - Business logic (search, tagging, rating)
   - Navigation and URL management
   - UI-specific state (zoom, dragging, scroll position)

2. **Tight Coupling**: Components directly access `Store.state` and call static methods like:
   - `Store.search()`, `Store.executeSearch()`
   - `Store.selectItem()`, `Store.toggleSelection()`
   - `Store.addTagsToSelection()`, `Store.removeTagFromSelection()`

3. **Callback-based Updates**: Uses `Store.needsRedraw()` with a global callback pattern instead of React's state management

4. **No Type Safety**: CoffeeScript with no TypeScript benefits

## Proposed Modern Architecture

### 1. Core Context Structure

Based on your actual Store usage patterns, here's the recommended structure:

#### `ItemsContext` - Core item management
```typescript
interface ItemsState {
  items: Record<number, number>; // index -> itemId mapping
  itemsById: Record<number, Item>;
  details: Record<number, ItemDetails>;
  resultCount: number | null;
  searchKey: string | null;
  searching: boolean;
}

interface ItemsActions {
  fetchItem: (itemId: number) => Promise<Item | null>;
  fetchItemDetails: (itemId: number, force?: boolean) => Promise<ItemDetails>;
  executeSearch: (start: number, end: number) => Promise<void>;
  updateItems: (items: Item[]) => void;
  clearItems: () => void;
}
```

#### `SearchContext` - Search and query management
```typescript
interface SearchState {
  query: string;
  parsedQuery: SearchQuery | null;
  loading: boolean;
  error: string | null;
}

interface SearchActions {
  setQuery: (query: string) => void;
  search: (query: string, force?: boolean) => Promise<void>;
  clearSearch: () => void;
}
```

#### `SelectionContext` - Selection and batch operations
```typescript
interface SelectionState {
  selection: Record<number, boolean>;
  selectionCount: number;
  selectMode: boolean;
  rangeStart: number | null;
  dragStart: number | null;
  dragEnd: number | null;
  dragging: Record<number, boolean>;
  pendingTags: TagMatch[];
  pendingTagString: string;
  lastTags: Tag[];
}

interface SelectionActions {
  selectItem: (id: number, value?: boolean) => void;
  toggleSelection: (id: number) => void;
  selectRange: (itemId: number, value?: boolean) => void;
  clearSelection: () => void;
  addTagsToSelection: (tags: Tag[]) => Promise<void>;
  removeTagFromSelection: (tagId: number) => Promise<void>;
  changeSelectionVisibility: (value: boolean) => Promise<void>;
  shareSelection: () => Promise<string>;
}
```

#### `TagsContext` - Tag management
```typescript
interface TagsState {
  tags: Tag[];
  tagsById: Record<number, Tag>;
  tagsLoaded: boolean;
  tagIconChoices: number[] | null;
  tagIconChoicesId: number | null;
}

interface TagsActions {
  loadTags: () => Promise<void>;
  createTag: (label: string, icon?: number) => Promise<Tag>;
  updateTag: (tag: Tag) => Promise<void>;
  deleteTag: (id: number) => Promise<void>;
  loadIconChoices: (tag: Tag) => Promise<number[]>;
}
```

#### `UIContext` - UI-specific state
```typescript
interface UIState {
  zoom: number;
  highlight: string | null;
  hasTouch: boolean;
  openStack: string[];
  judgeIcons: boolean;
}

interface UIActions {
  setZoom: (level: number) => void;
  setHighlight: (highlight: string | null) => void;
  pushToStack: (item: string) => void;
  popFromStack: () => string | undefined;
  toggleJudgeIcons: () => void;
}
```

#### `UserContext` - User permissions and activity
```typescript
interface UserState {
  canWrite: boolean;
  isAdmin: boolean;
  recent: {
    activity: Activity[];
    sources: Source[];
    taggings: Tagging[];
  } | null;
}

interface UserActions {
  loadCurrentUser: () => Promise<void>;
  loadRecentActivity: () => Promise<void>;
}
```

### 2. Custom Hooks for Complex Logic

#### `useItemOperations` - Item rating and actions
```typescript
function useItemOperations() {
  const rateItem = async (itemId: number, rating: number) => { ... };
  const toggleItemStar = async (itemId: number) => { ... };
  const toggleItemBullhorn = async (itemId: number) => { ... };
  
  return { rateItem, toggleItemStar, toggleItemBullhorn };
}
```

#### `useComments` - Comment management
```typescript
function useComments(itemId: number) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState(false);
  
  const addComment = async (text: string) => { ... };
  const loadComments = async () => { ... };
  
  return { comments, loading, addComment, loadComments };
}
```

#### `useNavigation` - URL and navigation management
```typescript
function useNavigation() {
  const navigate = (url: string) => { ... };
  const navigateWithoutHistory = (url: string) => { ... };
  const navigateBack = () => { ... };
  
  return { navigate, navigateWithoutHistory, navigateBack };
}
```

### 3. Migration Strategy

#### Phase 1: Infrastructure Setup
1. **Create Context Structure**
   - Set up all context providers
   - Create basic state management
   - Implement AJAX wrapper with proper error handling

2. **Create Provider Tree**
   ```typescript
   <UserProvider>
     <TagsProvider>
       <ItemsProvider>
         <SearchProvider>
           <SelectionProvider>
             <UIProvider>
               <App />
             </UIProvider>
           </SelectionProvider>
         </SearchProvider>
       </ItemsProvider>
     </TagsProvider>
   </UserProvider>
   ```

#### Phase 2: Core Feature Migration
1. **Tags System** (Most isolated)
   - Migrate tag loading and management
   - Update `TagEditor`, `TagList` components
   - Test tag CRUD operations

2. **User System** (Independent)
   - Migrate user permissions
   - Update authentication checks
   - Migrate recent activity

3. **Search System** (Core functionality)
   - Migrate search query parsing
   - Update search execution
   - Migrate result pagination

#### Phase 3: Complex Features
1. **Items Management**
   - Migrate item fetching and caching
   - Update item details loading
   - Migrate item operations (rating, starring)

2. **Selection System**
   - Migrate selection state
   - Update drag-and-drop selection
   - Migrate batch operations

#### Phase 4: UI State Migration
1. **UI State**
   - Migrate zoom controls
   - Update navigation stack
   - Migrate touch detection

2. **Component Updates**
   - Update all components to use contexts
   - Remove direct Store dependencies
   - Implement proper memoization

### 4. Specific Implementation Examples

#### Context Provider Example
```typescript
export const ItemsProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<ItemsState>(initialState);
  
  const fetchItem = async (itemId: number): Promise<Item | null> => {
    const item = state.itemsById[itemId];
    if (item) return item;
    
    try {
      const response = await api.get(`/items/${itemId}`);
      setState(prev => ({
        ...prev,
        itemsById: {
          ...prev.itemsById,
          [itemId]: response.data.item
        }
      }));
      return response.data.item;
    } catch (error) {
      console.error('Failed to fetch item:', error);
      return null;
    }
  };
  
  const value = {
    ...state,
    fetchItem,
    // ... other actions
  };
  
  return <ItemsContext.Provider value={value}>{children}</ItemsContext.Provider>;
};
```

#### Component Migration Example
```typescript
// Before (CoffeeScript)
component 'Results', ->
  items = []
  for i in [startIndex..endIndex]
    itemId = Store.state.items[i]
    item = Store.getItem itemId if itemId
    items.push item
  
  Store.executeSearch startIndex, endIndex

// After (TypeScript)
const Results: React.FC = () => {
  const { items, itemsById, executeSearch } = useItems();
  const { zoom } = useUI();
  
  const visibleItems = useMemo(() => {
    return range(startIndex, endIndex).map(i => {
      const itemId = items[i];
      return itemId ? itemsById[itemId] : null;
    });
  }, [items, itemsById, startIndex, endIndex]);
  
  useEffect(() => {
    executeSearch(startIndex, endIndex);
  }, [executeSearch, startIndex, endIndex]);
  
  return (
    <div className="results">
      {visibleItems.map(item => (
        <Item key={item?.id || 'loading'} item={item} />
      ))}
    </div>
  );
};
```

### 5. Key Benefits of This Approach

1. **Separation of Concerns**: Each context handles a specific domain
2. **Better Testing**: Each context can be tested independently
3. **Type Safety**: Full TypeScript support with proper interfaces
4. **Performance**: Granular updates and better memoization
5. **Maintainability**: Clear data flow and easier debugging

### 6. Migration Checklist

- [ ] Set up TypeScript configuration
- [ ] Create all context providers
- [ ] Implement AJAX wrapper with error handling
- [ ] Migrate tags system
- [ ] Migrate user system
- [ ] Migrate search functionality
- [ ] Migrate items management
- [ ] Migrate selection system
- [ ] Migrate UI state
- [ ] Update all components
- [ ] Remove Store class
- [ ] Update tests
- [ ] Performance optimization

### 7. Risk Mitigation

1. **Gradual Migration**: Keep Store class until all features are migrated
2. **Feature Flags**: Use feature flags to toggle between old and new implementations
3. **Comprehensive Testing**: Test each migrated feature thoroughly
4. **Rollback Plan**: Keep ability to rollback to Store class if needed

This modernization will significantly improve your codebase's maintainability, performance, and developer experience while preserving all existing functionality.