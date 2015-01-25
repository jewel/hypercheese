var SparseItem = Em.Object.create({
    isLoaded: false
});

Ember.SparseArray = Em.Object.extend(Em.Array, {
    length: 0,

    batchSize: 100,

    isLoaded: false,

    _data: null,

    _loadedIndexes: null,

    load: null,

    init: function() {
        this._data = {};
        this._loadedIndexes = {};
        this._super();
        Em.assert('`load` must be set to a function in the constructor of SparseArray', typeof this.get('load') === 'function');
        this._loadIndex(0);
    },

    objectAt: function(index) {
        var length = this.get('length');
        if (index < 0)
          return null;
        if (index >= length) {
            return null;
        }
        if (typeof this._data[index] === 'undefined') {
            if (this._loadedIndexes[index] !== true) {
                //Stop Ember.Array from trying to get the `lastObject` property
                if (!this._ignoreLastObject || index !== length-1) {
                    this._loadIndex(index);
                }
            }
            return SparseItem;
        }
        return this._data[index];
    },

    _loadIndex: function(index) {
        var self = this,
            loadedIndexes = this._loadedIndexes,
            batchSize = this.get('batchSize'),
            halfBatchSize = Math.ceil(batchSize/2),
            startOffset = index,
            endOffset = index;

        while (true) {
            loadedIndexes[startOffset] = true;
            if (loadedIndexes[startOffset - 1] === true || startOffset <= Math.max(0, index - halfBatchSize)) {
                break;
            }
            startOffset--;
        }

        while (true) {
            loadedIndexes[endOffset] = true;
            if (loadedIndexes[endOffset + 1] === true || endOffset >= startOffset + batchSize - 1) {
                break;
            }
            endOffset++;
        }

        var promise = self.load(startOffset, endOffset - startOffset + 1);
        Em.assert('`load` for SparseArray must return a thenable', promise && typeof promise.then === 'function');

        promise.then(function(payload) {
            Em.assert('The promise returned from `load` for SparseArray must resolve with an object', typeof payload === 'object');
            Em.assert('The promise returned from `load` for SparseArray must resolve with an object with an array named `items`', Em.isArray(payload.items));
            Em.assert('The promise returned from `load` for SparseArray must resolve with an object with an integer named `total`', typeof payload.total === 'number');

            self._ignoreLastObject = true;

            var oldLength = self.get('length'),
                newLength = payload.total,
                items = payload.items,
                itemsLength = items.length,
                itemsRemoved = Math.min(itemsLength, oldLength - startOffset);

            self.arrayContentWillChange(startOffset, itemsRemoved, itemsLength);
            if (newLength !== oldLength) {
                self.set('length', newLength);
            }
            for (var i = 0; i < itemsLength; i++) {
                self._data[startOffset + i] = items[i];
            }
            self.arrayContentDidChange(startOffset, itemsRemoved, itemsLength);

            //If length changed
            if (newLength !== oldLength) {
                var start,
                    endRemoved,
                    endAdded;
                
                if (newLength > oldLength) {
                    //Items were added to the end
                    start = Math.max(startOffset + itemsLength, oldLength);
                    endRemoved = 0;
                    endAdded = newLength - Math.max(startOffset + itemsLength, oldLength);
                } else {
                    //Items were removed from the end
                    start = newLength;
                    endRemoved = oldLength - newLength;
                    endAdded = 0;
                }
                self.arrayContentWillChange(start, endRemoved, endAdded);
                self.arrayContentDidChange(start, endRemoved, endAdded);
            }

            if (!self.get('isLoaded')) {
                self.set('isLoaded', true);
            }

            self._ignoreLastObject = false;
        }, function(e) {
            console.error('SparseArray load error', e);
        });
    }
});
