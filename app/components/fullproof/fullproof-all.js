/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
var fullproof = fullproof||{};
(function() {
"use strict";

    /**
     * A prototype for Analyzers objects.
     * @constructor
     */
    fullproof.AbstractAnalyzer = function() {
        /**
         * Sometimes it's convenient to receive the whole set of words cut and normalized by the
         * analyzer. This method calls the callback parameter only once, with as single parameter
         * an array of normalized words.
         * @param text some text to analyze
         * @param callback a function called with an array (possibly empty) of string
         */
        this.getArray = function(text, callback) {
            var parser_synchro = fullproof.make_synchro_point(function(array_of_words) {
                callback(array_of_words);
            });
            this.parse(text, parser_synchro);
        };

    };

	/**
	 * A simple private parser that relies on the unicode letter/number
	 * categories. Word boundaries are whatever is not a letter 
	 * or a number.
	 */
	var simple_parser = function(str, callback, functor) {
		functor = functor||net.kornr.unicode.is_letter_number;
		var current_word = "";
		for (var i=0,max=str.length; i<max; ++i) {
			if (functor(str.charCodeAt(i))) {
				current_word += str[i];
			} else {
				if (current_word.length>0) {
					callback(current_word);
					current_word = "";
				}
			}
		}
		if (current_word.length>0) {
			callback(current_word);
		}
		callback(false);
	};
	
	function arguments_to_array(args) {
		var result = [];
		for (var i=0; i<args.length; ++i) {
			if (args[i].constructor == Array) {
				result = result.concat(args[i]);
			} else {
				result.push(args[i]);
			}
		}
		return result;
	}
	
	/**
	 * An analyzer with a parse() method. An analyzer does more than
	 * just parse, as it normalizes each word calling the sequence
	 * of normalizers specified when calling the constructor.
	 * 
	 * @constructor
	 * @param normalizers... the constructor can take normalizers as parameters. Each 
	 * normalizer is applied sequentially in the same order as they are
	 * passed in the constructor.
	 */
	fullproof.StandardAnalyzer = function() {
        var normalizers = arguments_to_array(arguments);

        // Enforces new object
		if (!(this instanceof fullproof.StandardAnalyzer)) {
			return new fullproof.StandardAnalyzer(normalizers);
		}

		// Stores the normalizers... (don't store arguments, as it contains more than an array) 
		this.provideScore = false;
		/**
		 * When true, the parser calls its callback function with 
		 * the parameter {boolean}false when complete. This allows
		 * the callback to know when the parsing is complete. When
		 * this property is set to false, the parser never triggers
		 * the last call to callback(false).
		 * 
		 * @expose
		 */
		this.sendFalseWhenComplete = true;

        function applyNormalizers(word, offset, callback) {
            if (offset>=normalizers.length) {
                return callback(word);
            }
            return normalizers[offset](word, offset>=normalizers.length?callback:function applyNormalizerRecCall(w) { if (w) applyNormalizers(w, offset+1, callback); });
        }

		/**
         * The main method: cuts the text in words, calls the normalizers on each word,
         * then calls the callback with each non empty word.
         * @param text the text to analyze
         * @param callback a function called with each word found in the text.
         */
        this.parse = function (text, callback) {
            var self = this;
            simple_parser(text, function (word) {
                if (typeof word === "string") {
                    applyNormalizers(word.trim(), 0, callback);
                } else if (word === false && self.sendFalseWhenComplete && callback) {
                    callback(false);
                }
            });
        };
	};

    fullproof.StandardAnalyzer.prototype = new fullproof.AbstractAnalyzer();

    /**
     * The ScoringAnalyzer is not unlike the StandardAnalyzer, except that is attaches a score to each token,
     * related to its place in the text. This is a very naive implementation, and therefore the adjustement
     * is tweaked to be very light: it simplistically says that the more a token is near the start of the text,
     * the more relevant it is to the document. Although very simple, it follows the normally expected form
     * of a text where the headers and titles come first, and should provide decent result. You can use
     * this as a basis and make a ScoringAnalyzer adapted to your data.
     * @constructor
     */
	fullproof.ScoringAnalyzer = function() {
		// Stores the normalizers... (don't store arguments, as it contains more than an array) 
		var normalizers = arguments_to_array(arguments);
		var analyzer = new fullproof.StandardAnalyzer(normalizers);
		this.sendFalseWhenComplete = analyzer.sendFalseWhenComplete = true;
		this.provideScore = true;
		
		this.parse = function (text, callback) {
            var words = {};
            var wordcount = 0;
            var totalwc = 0;
            var self = this;
            analyzer.parse(text, function (word) {
                if (word !== false) {
                    if (words[word] === undefined || words[word].constructor !== Array) {
                        words[word] = [];
                    }
                    words[word].push(wordcount);
                    totalwc += ++wordcount;
                } else {
                    // Evaluate the score for each word
                    for (var w in words) {
                        var res = words[w];
                        var offsetcount = 1;
                        var occboost = 0;
                        for (var i = 0; i < res.length; ++i) {
                            occboost += (3.1415 - Math.log(1 + res[i])) / 10;
                        }
                        var countboost = Math.abs(Math.log(1 + res.length)) / 10;
                        var score = 1 + occboost * 1.5 + countboost * 3;
                        // console.log(w + ": " + words[w].join(",") + ", countboost: " + countboost + ", occboost: " + occboost);
                        callback(new fullproof.ScoredEntry(w, undefined, score));
                    }

                    if (self.sendFalseWhenComplete == true) {
                        callback(false);
                    }

                }
            });
        };
		

	};
    fullproof.ScoringAnalyzer.prototype = new fullproof.AbstractAnalyzer();


})();
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var fullproof = fullproof||{};

/**
 * A boolean-set based engine.
 *
 * @constructor
 */
fullproof.BooleanEngine = function (storeDescriptors) {

    if (!(this instanceof fullproof.BooleanEngine)) {
        return new fullproof.BooleanEngine(storeDescriptors);
    }

    this.initAbstractEngine(storeDescriptors); // Init from the prototype

    /**
     * The working mode when gathering result sets. There's no really any good reason to change this,
     * but whatever, you can if you want.
     */
    this.booleanMode = fullproof.BooleanEngine.CONST_MODE_INTERSECT;

    /**
     * Gather results for a query
     * @param self the BooleanEngine instance it works with
     * @param text the text query too look up in the indexes
     * @param callback a function called when some results are found. Receives an argument: false if failed to get any result, or a resultset if some documents were found.
     * @param arrayOfIndexUnits a mutable array of IndexUnits that is recursively consumed, and that contains references to the indexes to use.
     * @param mode The search mode, normally this should be self.booleanMode
     * @private
     */
    function lookup(self, text, callback, arrayOfIndexUnits, mode) {
        if (arrayOfIndexUnits.length == 0) {
            return callback(false);
        }
        var unit = arrayOfIndexUnits.shift();
        ++(self.lastResultIndex);
        unit.analyzer.parse(text, fullproof.make_synchro_point(function (array_of_words) {

            if (!array_of_words || array_of_words.length == 0) {
                if (arrayOfIndexUnits.length > 0) {
                    return lookup(self, text, callback, arrayOfIndexUnits, mode);
                } else {
                    return callback(false);
                }
            }

            var lookup_synchro = fullproof.make_synchro_point(function (rset_array) {

                var curset = rset_array.shift();
                while (rset_array.length > 0) {
                    var set = rset_array.shift();
                    switch (mode) {
                        case fullproof.BooleanEngine.CONST_MODE_UNION:
                            curset.merge(set);
                            break;
                        default: // default is intersect
                            curset.intersect(set);
                            break;
                    }
                }

                if (curset.getSize() == 0) {
                    if (arrayOfIndexUnits.length > 0) {
                        return lookup(self, text, callback, arrayOfIndexUnits, mode);
                    } else {
                        callback(false);
                    }
                } else {
                    callback(curset);
                }

            }, array_of_words.length);

            for (var i = 0; i < array_of_words.length; ++i) {
                unit.index.lookup(array_of_words[i], lookup_synchro);
            }
        }));
    }

    /**
     * Looks up in the indexes for the query.
     * @param text the query text to look up
     * @param callback function called when the lookup is complete. It is passed false if nothing was found, or a ResultSet otherwise.
     */
    this.lookup = function (text, callback) {
        this.lastResultIndex = 0;
        lookup(this, text, callback, this.getIndexUnits(), this.booleanMode);
        return this;
    }
};

fullproof.AbstractEngine = fullproof.AbstractEngine || (function() {});
fullproof.BooleanEngine.prototype = new fullproof.AbstractEngine;
/**
 * @const
 */
fullproof.BooleanEngine.CONST_MODE_INTERSECT = 1;
/**
 * @const
 */
fullproof.BooleanEngine.CONST_MODE_UNION = 2;
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};

/**
 * Represents a set of contraints applied to an index or a store.
 * The way this object is designed, you only have to set the properties that are meaningful for your
 * requirement. Not setting a property means that any value is ok.
 * @constructor
 */
fullproof.Capabilities = function() {
	if (!(this instanceof fullproof.Capabilities)) {
		return new fullproof.Capabilities();
	}
};

/**
 * Compares a value with a property of this Capabilities object.
 * @param property a property name
 * @param value the valued to be compared
 * @protected
 * This should probably be made private or something
 */
fullproof.Capabilities.prototype.matchValue = function (property, value) {
    if (value === undefined) {
        return true;
    } else if (typeof property == "object" && property.constructor == Array) {
        for (var i = 0; i < property.length; ++i) {
            if (property[i] === value) {
                return true;
            }
        }
        return false;
    } else {
        return property === value;
    }
};
/**
 *
 */
fullproof.Capabilities.prototype.setStoreObjects = function (val) {
    this.canStoreObjects = val;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getStoreObjects = function () {
    return this.canStoreObjects;
};
/**
 *
 */
fullproof.Capabilities.prototype.setVolatile = function (val) {
    this.isVolatile = val;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.setAvailable = function (val) {
    this.isAvailable = !!val;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.setUseScores = function (val) {
    this.useScores = val;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getUseScores = function () {
    return this.useScores;
};
/**
 *
 */
fullproof.Capabilities.prototype.setComparatorObject = function (obj) {
    this.comparatorObject = obj;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getComparatorObject = function (obj) {
    return this.comparatorObject;
};
/**
 *
 */
fullproof.Capabilities.prototype.setDbName = function (name) {
    this.dbName = name;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getDbName = function () {
    return this.dbName;
};
/**
 *
 */
fullproof.Capabilities.prototype.setDbSize = function (size) {
    this.dbSize = size;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getDbSize = function () {
    return this.dbSize;
};
/**
 *
 */
fullproof.Capabilities.prototype.setScoreModifier = function (modifier) {
    this.scoreModifier = modifier;
    return this;
};
/**
 *
 */
fullproof.Capabilities.prototype.getScoreModifier = function () {
    return this.scoreModifier;
};
/**
 * Returns true if the current Capabilities object subsumes another Capabilities.
 * @param otherCapabilities the Capabilities that must be subsumed by the current instance
 */
fullproof.Capabilities.prototype.isCompatibleWith = function (otherCapabilities) {
    var objstore = this.matchValue(this.canStoreObjects, otherCapabilities.canStoreObjects);
    var isvol = this.matchValue(this.isVolatile, otherCapabilities.isVolatile);
    var score = this.matchValue(this.useScores, otherCapabilities.useScores);
    var isavail = this.isAvailable === true;

    return objstore && isvol && isavail && score;
};
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var fullproof = fullproof || {};

/**
 * A TextInjector associates an index and an analyzer to provide an
 * object able to inject texts.
 * 
 * @constructor
 * @param index the index to use when injecting
 * @param analyzer the analyzer to use to parse and normalize the text
 * TODO: move this object in its own place or in utils
 */
fullproof.TextInjector = function(index, analyzer) {
	if (!(this instanceof fullproof.TextInjector)) {
		return new fullproof.TextInjector(index,analyzer);
	}
	this.index = index;
	this.analyzer = analyzer;
};

/**
 * Inject a text and associates each of the word it composed with the provided value.
 * @param text some text to inject in the index
 * @param value the value associated to each word from the text
 * @param callback a function to call when the injection is complete
 */
fullproof.TextInjector.prototype.inject = function(text,value,callback) {
	var self = this;
	this.analyzer.getArray(text, function(array_of_words) {
		var synchro = fullproof.make_synchro_point(callback, array_of_words.length);
		for (var i=0; i<array_of_words.length; ++i) {
			var val = array_of_words[i];
			if (val instanceof fullproof.ScoredEntry) {
				val.value = val.value===undefined?value:val.value;
				self.index.inject(val.key, val, synchro); // the line number is the value stored
			} else {
				self.index.inject(array_of_words[i], value, synchro); // the line number is the value stored
			}
		}
	});
};

/**
 * Bulk-inject an array of  text and an array of values. The text injected is associated to the value
 * of the same index from the valueArray array. An optional progress function is called at regular interval
 * to provide a way for the caller to give user feedback on the process.
 * 
 * @param texArray an array of text
 * @param valueArray an array of values. The length of valueArray must equal the length of textArray.
 * @param callback a function to call when the injection is complete
 * @param progressCallback a function called with progress indication. A numeric argument is provided to 
 * the function, which ranges from 0 to 1 (0 meaning not done, 1 meaning complete). Note that due to the
 * floating nature of numeric values in javascript, you should not rely on receiving a 1, rather use
 * the callback function parameter, which will be always called on completion of the injection.
 */
fullproof.TextInjector.prototype.injectBulk = function(textArray, valueArray, callback, progressCallback) {
	var words = [];
	var values = [];
	var self = this;
	for (var i=0, max=Math.min(textArray.length, valueArray.length); i<max; ++i) {
		(function(text,value) {
			self.analyzer.getArray(text, function(array_of_words) {
				for (var w=0; w<array_of_words.length; ++w) {
					var val = array_of_words[w];
					if (val instanceof fullproof.ScoredEntry) {
						val.value = val.value===undefined?value:val.value;
						words.push(val.key);
						values.push(val);
					} else {
						words.push(val);
						values.push(value);
					}
				}
			});
		})(textArray[i], valueArray[i]);
	}
	this.index.injectBulk(words,values, callback, progressCallback);
}; 

/**
 * Represent all the data associated to an index, from the point of view of a search engine.
 * @param name the name of the index, expected to be unique in the search engine
 * @param capabilities a fullproof.Capabilities
 * @param analyzer
 * @param initializer
 * @param index
 * @constructor
 */
fullproof.IndexUnit = function (name, capabilities, analyzer, initializer, index) {
    /**
     * The name of the index
     */
    this.name = name;
    /**
     * The fullproof.Capabilities object originally associated to the index
     */
    this.capabilities = capabilities;
    /**
     * The parser used to inject text in the index
     */
    this.analyzer = analyzer;
    /**
     * The initializer function when the index needs to be built
     * @type {*}
     */
    this.initializer = initializer;
    /**
     * The index itself
     */
    this.index = index;
};

fullproof.AbstractEngine = fullproof.AbstractEngine || (function() {});

fullproof.AbstractEngine.prototype.checkCapabilities = function (capabilities, analyzer) {
    return true;
};

/**
 * Adds an array of index units
 * @param indexes an array of fullproof.IndexUnit instances
 * @param callback the function to call when all the indexes are added
 * @private
 * @static
 */
fullproof.AbstractEngine.addIndexes = function (engine, indexes, callback) {
    var starter = false;
    while (indexes.length > 0) {
        var data = indexes.pop();
        starter = (function (next, data) {
            return function () {
                fullproof.AbstractEngine.addIndex(engine, data.name, data.analyzer, data.capabilities, data.initializer, next !== false ? next : callback);
            };
        })(starter, data);
    }
    if (starter !== false) {
        starter();
    }
    return this;
};

/**
 * Adds un index to the engine. It is not possible to add an index after the engine was opened.
 * @param name the name of the engine
 * @param the analyzer used to parse the text
 * @param capabilities a fullproof.Capabilities instance describing the requirements for the index
 * @param initializer a function called when the index is created. This function can be used to populate the index.
 * @param completionCallback a function on completion, with true if the index was successfully added, false otherwise.
 * @return this instance
 * @private
 * @static
 */
fullproof.AbstractEngine.addIndex = function(engine, name, analyzer, capabilities, initializer, completionCallback) {
	var self = engine;
	var indexData = new fullproof.IndexUnit(name,capabilities,analyzer); 

	if (!engine.checkCapabilities(capabilities, analyzer)) {
		return completionCallback(false);
	}

	var indexRequest = new fullproof.IndexRequest(name, capabilities, function(index, callback) {
		var injector = new fullproof.TextInjector(index, indexData.analyzer);
		initializer(injector, callback);
	});
	
	if (engine.storeManager.addIndex(indexRequest)) {
		if (engine.indexes === undefined) {
            engine.indexes = [];
		}
        engine.indexes.push(indexData);
        engine.indexesByName[name] = indexData;
		if (completionCallback) {
			completionCallback(true);
		}
		return true;
	} else {
		if (completionCallback) {
			completionCallback(false);
		}
		return false;
	}
};

/**
 * Opens the engine: this function opens all the indexes at once, makes the initialization if needed,
 *  and makes this engine ready for use. Do not use any function of an engine, except addIndex, before
 *  having opened it.
 *  @param indexArray an array of index descriptors. Each descriptor is an object that defines the name, analyzer, capabilities, and initializer properties.
 *  @param callback function called when the engine is properly opened
 *  @param errorCallback function called if for some reason the engine cannot open some index
 */
fullproof.AbstractEngine.prototype.open = function (indexArray, callback, errorCallback) {
    var self = this;
    indexArray = (indexArray.constructor !== Array)?[indexArray]:indexArray; // Makes it an Array if it's not
    fullproof.AbstractEngine.addIndexes(self, indexArray);

    this.storeManager.openIndexes(function (storesArray) {
        self.storeManager.forEach(function (name, index) {
            self.indexesByName[name].index = index;
        });
        callback(self);
    }, errorCallback);
    return this;
};

/**
 * Inject a text document into all the indexes managed by the engine.
 * @param text some text to be parsed and indexed
 * @param value the primary value (number or string) associated to this object.
 * @param callback the function called when the text injection is done
 */
fullproof.AbstractEngine.prototype.injectDocument = function(text, value, callback) {
	var synchro = fullproof.make_synchro_point(function(data) {
		callback();
	});

	this.forEach(function(name, index, parser) {
		if (name) {
			parser.parse(text, function(word) {
				if (word) {
					index.inject(word, value, synchro); // the line number is the value stored
				} else {
					synchro(false);
				}
			})
		}
	}, false);
	return this;
};

/**
 * Clears all the indexes managed by this engine. Do not call this function
 * before the engine was open()'ed.
 * @param callback a function called when all the indexes are cleared.
 */
fullproof.AbstractEngine.prototype.clear = function(callback) {
    "use strict";
    if (this.getIndexCount() === 0) {
        return callback();
    }
	var synchro = fullproof.make_synchro_point(callback, this.getIndexCount());
	this.forEach(function(name, index, parser) {
		if (name) {
			index.clear(synchro);
		} else {
			synchro(false);
		}
	});
};

/**
 * Inits the current engine with data used by the AbstractEngine object.
 */
fullproof.AbstractEngine.prototype.initAbstractEngine = function (storeDescriptors) {
    this.storeManager = new fullproof.StoreManager(storeDescriptors);
    this.indexes = [];
    this.indexesByName = {};
    return this;
};

/**
 * Returns an index by its name
 * @param name the index name
 * @return a store index
 */
fullproof.AbstractEngine.prototype.getIndex = function (name) {
    return this.indexesByName[name].index;
};

/**
 * Returns an array with all the fullproof.IndexUnit managed by the engine,
 * in the same order they were added. The returned array is a shallow copy than
 * can be modified.
 * @return an array, possibly empty, of fullproof.IndexUnit objects.
 */
fullproof.AbstractEngine.prototype.getIndexUnits = function () {
    return [].concat(this.indexes);
};

/**
 * Iterates over the indexes, in order, and calls the callback function with 3 parameters:
 * the name of the index, the index instance itself, and the analyzer associated to this index.
 * @param callback the callback function(name,index,analyzer){}
 * @return this engine instance
 */
fullproof.AbstractEngine.prototype.forEach = function (callback) {
    for (var i = 0, max = this.indexes.length; i < max; ++i) {
        callback(this.indexes[i].name, this.indexes[i].index, this.indexes[i].analyzer);
    }
    for (var i = 1; i < arguments.length; ++i) {
        callback(arguments[i]);
    }
    return this;
};

fullproof.AbstractEngine.prototype.getIndexCount = function () {
    return this.indexes.length;
};
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var fullproof = fullproof || {};
fullproof.normalizer = fullproof.normalizer || {};

	//
	// Normalizing functions take a word and return another word.
	// If the word is cancelled by a function, it gets replaced 
	// by the boolean value false, otherwise it returns and/or
	// sends forward the callback chain the new normalized form 
	// for the word (or the unchanged form, if the normalizer
	// doesn't perform any transformation).
	//

/**
 * Converts a word into a canonical Unicode decomposed and lowercased form.
 * @param word a token to transform
 * @param callback a function called with the converted word (optional)
 * @return the result of the callback function, or the converted word is there is no callback.
 */
fullproof.normalizer.to_lowercase_decomp = function(word, callback) {
    word = word?net.kornr.unicode.lowercase(word):word;
    return callback?callback(word):word;
};

/**
 * Convertes a word to lowercase and remove all its diacritical marks.
 * @param word a token to transform
 * @param callback a function called with the converted word (optional)
 * @return the result of the callback function, or the converted word is there is no callback.
 */
fullproof.normalizer.to_lowercase_nomark = function(word, callback) {
    word = word?net.kornr.unicode.lowercase_nomark(word):word;
    return callback?callback(word):word;
};

/**
 * Remove all the duplicate letters in a word. For instance TESSTT is converted to TEST, CHEESE is converted to CHESE.
 * @param word a token to transform
 * @param callback a function called with the converted word (optional)
 * @return the result of the callback function, or the converted word is there is no callback.
 */
fullproof.normalizer.remove_duplicate_letters = function(word, callback) {
    var res = word?"":false;
    var last = false;
    if (word) {
        for (var i=0,max=word.length; i<max; ++i) {
            if (last) {
                if (last != word[i]) {
                    res +=last;
                }
            }
            last = word[i];
        }
        res += last?last:"";
    }
    return callback?callback(res):res;
};

/**
 *
 * @param word
 * @param array
 * @param callback
 * @return {*}
 */
fullproof.normalizer.filter_in_object = function(word, array, callback) {
    if (array[word]) {
        return callback?callback(false):false;
    }
    return callback?callback(word):word;
};
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};

(function() {
"use strict";

	var defaultComparator = {
		lower_than: function(a,b) {
			return a<b;
		},
		equals: function(a,b) {
			return a==b;
		}
	};


	/**
     * Binary search an array.
     * @param array an array to search in
     * @param value the value to search for
     * @param min the floor index
     * @param max the ceil index
     * @param lower_than an optional function that takes two arguments and returns true if
     * the first argument is lower than the second one. You have to provide this function
     * if the values stored in the array cannot be sorted by the default javascript < operator.
     *
     * @return the index of the value, if found, or the index where the value can be inserted if not found.
     */
    fullproof.binary_search = function (array, value, min, max, lower_than) {
        lower_than = lower_than || defaultComparator.lower_than;
        if (min === undefined && max === undefined) {
            if (array.length == 0) {
                return 0
            } else {
                return fullproof.binary_search(array, value, 0, array.length, lower_than);
            }
        }

        while (max >= min) {
            var mid = parseInt((max + min) / 2);
            if (mid >= array.length) {
                return array.length;
            } else if (lower_than(array[mid], value)) {
                min = mid + 1;
            } else if (lower_than(value, array[mid])) {
                max = mid - 1;
            } else {
                // Found
                return mid;
            }
        }
        // Not found
        return min;
    };
	
	/**
	 *  Provides an object containing a sorted array, and providing elementary
	 *  set operations: merge (union), intersect, and substract (complement).
	 *  It maintains internally a sorted array of data. The optional comparator
	 *  must be an object of the form {lower_than: func_lt, equals: func_equal}
	 *  
	 *  @constructor
	 *  @param comparatorObject a comparator object that provides two functions: lower_than and equals.
	 *  If not defined, a default comparator using the javascript < operator is used. If you're only 
	 *  storing integer values, you can safely omit this argument.
	 */
	fullproof.ResultSet = function(comparatorObject, data) {
		if (!(this instanceof fullproof.ResultSet)) {
			return new fullproof.ResultSet(comparatorObject,data);
		}
		this.comparatorObject = comparatorObject||defaultComparator;
		this.data = data||[];
		this.last_insert = undefined;
	};

	/**
	 * Insert values into the array of data managed by this ResultSet. The insertion is optimized 
	 * when the inserted values are greater than the last inserted values (the value is just pushed
	 * to the end of the array). Otherwise, a binary search is done in the array to find the correct
	 * offset where to insert the value. When possible, always insert sorted data.
	 * 
	 * @param values... any number of values to insert in this resultset.
	 */
	fullproof.ResultSet.prototype.insert = function() {
		for (var i=0; i<arguments.length; ++i) {
			var obj = arguments[i];
			
			if (this.last_insert && this.comparatorObject.lower_than(this.last_insert,obj)) {
				this.data.push(obj);
				this.last_insert = obj
			} else {
				var index = fullproof.binary_search(this.data, obj, undefined, undefined, this.comparatorObject.lower_than);
				if (index >= this.data.length) {
					this.data.push(obj);
					this.last_insert = obj
				} else if (this.comparatorObject.equals(obj, this.data[index]) === false) {
					this.data.splice(index, 0, arguments[i]);
					this.last_insert = undefined;
				}
			}
		}
		return this;
	};

	function defaultMergeFn(a,b) {
		return a;
	}
	
	/**
     * Union operation. Merge another ResultSet or a sorted javascript array into this ResultSet.
     * If the same value exists in both sets, it is not injected in the current set, to avoid duplicate values.
     * @param set another ResultSet, or an array of sorted values
     * @return this ResultSet, possibly modified by the merge operation
     */
    fullproof.ResultSet.prototype.merge = function (set, mergeFn) {
        mergeFn = mergeFn || defaultMergeFn;
        this.last_insert = undefined;
        var other = false;

        if (set.constructor == Array) {
            other = set;
        } else if (set instanceof fullproof.ResultSet) {
            other = set.getDataUnsafe();
        }


        var i1 = 0, max1 = this.data.length,
            i2 = 0, max2 = other.length,
            obj1 = null, obj2 = null;
        var comp = this.comparatorObject;

        var result = [];
        while (i1 < max1 && i2 < max2) {
            obj1 = this.data[i1];
            obj2 = other[i2];
            if (comp.equals(obj1, obj2)) {
                result.push(mergeFn(obj1, obj2));
                ++i1;
                ++i2;
            } else if (comp.lower_than(obj1, obj2)) {
                result.push(obj1);
                ++i1;
            } else {
                result.push(obj2);
                ++i2;
            }
        }
        while (i1 < max1) {
            result.push(this.data[i1]);
            ++i1;
        }
        while (i2 < max2) {
            result.push(other[i2]);
            ++i2;
        }
        this.data = result;
        return this;
    };
	

	/**
     * Intersect operation. Modify the current ResultSet so that is only contain values that are also contained by another ResultSet or array.
     * @param set another ResultSet, or an array of sorted values
     * @return this ResultSet, possibly modified by the intersect operation
     */
    fullproof.ResultSet.prototype.intersect = function (set) {
        this.last_insert = undefined;
        var other = false;
        if (set.constructor == Array) {
            other = set;
        } else if (set instanceof fullproof.ResultSet) {
            other = set.getDataUnsafe();
        }

        if (other) {
            var result = [];
            var i = 0, j = 0, maxi = this.data.length, maxj = other.length;
            while (i < maxi) {
                while (j < maxj && this.comparatorObject.lower_than(other[j], this.data[i])) {
                    ++j;
                }
                if (j < maxj && this.comparatorObject.equals(other[j], this.data[i])) {
                    result.push(other[j]);
                    ++i;
                    ++j;
                } else {
                    i++;
                }
            }
            this.data = result;
        } else {
            this.data = [];
        }
        return this;
    };

	
	/**
	 * Substraction operation. Modify the current ResultSet so that any value contained in the provided set of values are removed.
	 * @param set another ResultSet, or an array of sorted values
	 * @return this ResultSet, possibly modified by the substract operation
	 */
	fullproof.ResultSet.prototype.substract = function(set) {
		this.last_insert = undefined;
		var other = false;
		if (set.constructor == Array) {
			other = set;
		} else if (set instanceof fullproof.ResultSet) {
			other = set.getDataUnsafe();
		}
		
		if (other) {
			var result = [];
			var i=0,j=0,maxi=this.data.length,maxj=other.length;
			while (i<maxi) {
				while (j<maxj && this.comparatorObject.lower_than(other[j],this.data[i])) {
					++j;
				}
				if (j<maxj && this.comparatorObject.equals(other[j],this.data[i])) {
					++i; 
					++j;
				} else {
					result.push(this.data[i]);
					i++;
				}
			}
			this.data = result;
		} else {
			this.data = [];
		}
		
		return this;
	};

	/**
     * Returns the value stored at a given offset
     * @param i the offset of the value
     * @return a value stored by the resultset
     */
    fullproof.ResultSet.prototype.getItem = function (i) {
        return this.data[i];
    };

	/**
     * Returns the sorted javascript array managed by this ResultSet.
     */
    fullproof.ResultSet.prototype.getDataUnsafe = function () {
        return this.data;
    };

	/**
     * Sets the sorted array managed by this ResultSet.
     * @param sorted_array a sorted array
     * @return this ResultSet instance
     */
    fullproof.ResultSet.prototype.setDataUnsafe = function (sorted_array) {
        this.last_insert = undefined;
        this.data = sorted_array;
        return this;
    };

	/**
	 * Changes the comparatorObject associated to this set, and sorts the data.
	 * Use this function if you want to sort the data differently at some point.
	 * @param comparatorObject the comparator to use
	 * @return this ResultSet instance
	 */
	fullproof.ResultSet.prototype.setComparatorObject = function(comparatorObject) {
		this.comparatorObject = comparatorObject;
		var self = this;
		this.data.sort(function(a,b) {
			if (self.comparatorObject.lower_than(a,b)) {
				return -1;
			} else if (self.comparatorObject.equals(a,b)) {
				return 0;
			} else {
				return 1;
			}
		});
	};
	
	/**
     * Returns a string representation of this object's data.
     * @return a string
     */
    fullproof.ResultSet.prototype.toString = function () {
        return this.data.join(",");
    };

	/**
     * Iterates over all the element of the array, and calls the provided function with each values.
     * @param callback the function called with each element of the array
     * @return this ResultSet instance
     */
    fullproof.ResultSet.prototype.forEach = function (callback) {
        for (var i = 0, max = this.data.length; i < max; ++i) {
            callback(this.data[i]);
        }
        return this;
    };

	/**
     * Return the size of the managed array.
     */
    fullproof.ResultSet.prototype.getSize = function () {
        return this.data.length;
    };

	/**
	 * Creates a clone of this result set. The managed array is cloned too, but not
	 * the values it contains.
	 * @return a copy of this ResultSet.
	 */
	fullproof.ResultSet.prototype.clone = function() {
		var clone = new fullproof.ResultSet;
		clone.setDataUnsafe(this.data.slice(0));
		return clone;
	};
	
})();
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var fullproof = fullproof||{};

/**
 * This engine is based on scoring. During the injection of document, the parser must provide {fullproof.ScoredElement}
 * instances instead of primary values. The score is used to sort the results.
 *
 * @constructor
 */
fullproof.ScoringEngine = function (storeDescriptors) {
    if (!(this instanceof fullproof.ScoringEngine)) {
        return new fullproof.ScoringEngine(storeDescriptors);
    }

    this.initAbstractEngine(storeDescriptors);
};

fullproof.AbstractEngine = fullproof.AbstractEngine || (function() {});
fullproof.ScoringEngine.prototype = new fullproof.AbstractEngine();

fullproof.ScoringEngine.prototype.checkCapabilities = function (capabilities, analyzer) {
    if (capabilities.getUseScores() !== true) {
        throw "capabilities.getUseScore() must be true";
    }
    if (analyzer.provideScore !== true) {
        throw "analyzer.provideScore must be true";
    }
    if (!capabilities.getComparatorObject()) {
        throw "capabilities.getComparatorObject() must return a valid comparator";
    }

    return true;
};

fullproof.ScoringEngine.prototype.lookup = function(text, callback) {

	var units = this.getIndexUnits();

    function applyScoreModifier(resultset, modifier) {
        for (var i= 0, data=resultset.getDataUnsafe(), len=data.length; i<len; ++i){
            data[i].score *= modifier;
        }
    }

	function merge_resultsets(rset_array, unit) {
		if (rset_array.length == 0) {
			return new fullproof.ResultSet(unit.capabilities.getComparatorObject());
		} else {
			var set = rset_array.shift();
			while (rset_array.length > 0) {
				set.merge(rset_array.shift(), fullproof.ScoredElement.mergeFn);
			}
			return set;
		}
	}

	var synchro_all_indexes = fullproof.make_synchro_point(function(array_of_resultset) {
		var merged = merge_resultsets(array_of_resultset);
        merged.setComparatorObject({
            lower_than: function(a,b) {
                if (a.score != b.score) {
                    return a.score > b.score;
                } else {
                    return a.value < b.value;
                }
            },
            equals: function(a,b) {
                return a.score === b.score && a.value === b.value;
            }
        });
        callback(merged);
	}, units.length);

	for (var i=0; i<units.length; ++i) {
		var unit = units[i];
		unit.analyzer.parse(text, fullproof.make_synchro_point(function(array_of_words) {
			if (array_of_words) {
					if (array_of_words.length == 0) {
						callback(new fullproof.ResultSet(unit.capabilities.comparatorObject));
					} else {
						var lookup_synchro = fullproof.make_synchro_point(function(rset_array) {
							var merged = merge_resultsets(rset_array, unit);
                            if (unit.capabilities.getScoreModifier() !== undefined) {
                                applyScoreModifier(merged, unit.capabilities.getScoreModifier());
                            }
							synchro_all_indexes(merged);
						}, array_of_words.length);

						for (var i=0; i<array_of_words.length; ++i) {
							unit.index.lookup(array_of_words[i].key, lookup_synchro);
						}
					}
				}
		}));
	}
};
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};

/**
 * A descriptor for a store.
 * @constructor
 * @param name the public name for the store. Just needs to be different from others.
 * @param ref a reference to a fullproof.store.X function
 */
fullproof.StoreDescriptor = function(name, ref) {
	if (!(this instanceof fullproof.StoreDescriptor)) {
		return new fullproof.StoreDescriptor(name, ref);
	}
	this.name = name;
	this.ref = ref;
};

/**
 * A StoreManager finds and instanciates stores
 * @constructor
 * @param {Array.fullproof.StoreDescriptor} storeDescriptors an array of {fullproof.StoreDescriptor} instances. Just leave undefined to use the default stores.
 */
fullproof.StoreManager = function(storeDescriptors) {
	
	this.available = [];

	if (fullproof.store) {
		storeDescriptors = storeDescriptors || [ new fullproof.StoreDescriptor("websqlstore", fullproof.store.WebSQLStore),
            new fullproof.StoreDescriptor("indexeddbstore", fullproof.store.IndexedDBStore),
            new fullproof.StoreDescriptor("memorystore", fullproof.store.MemoryStore) ];
	}
    if (storeDescriptors && storeDescriptors.length) {
        for (var i=0;i<storeDescriptors.length; ++i) {
            if (storeDescriptors[i].ref) { // only push the store if it exists (.ref != undefined)
                this.available.push(storeDescriptors[i]);
            }
        }
    }

    this.indexes = {};
	this.indexesByStore = {};
	this.storeCount = 0;
	this.storeCache= {};
	this.selectedStorePool = [];
	var self = this;

	function selectSuitableStore(requiredCaps, pool) {
		if (pool.constructor != Array || pool.length==0) {
			return false;
		}
		for (var i=0; i<pool.length; ++i) {
			if (pool[i].ref.getCapabilities().isCompatibleWith(requiredCaps)) {
				return pool[i];
			}
		}
		return false;
	}

	/**
	 * Adds an index to the list of index managed by the StoreManager.
	 * @param indexRequest an instance of fullproof.IndexRequest that describes the index to add
	 * @return true if an appropriate store was found, false otherwise
	 */
	this.addIndex = function(indexRequest) {
		var candidateStore = selectSuitableStore(indexRequest.capabilities, [].concat(this.available));
		this.indexes[indexRequest.name] = {req: indexRequest, storeRef: candidateStore };
		if (candidateStore) {
			if (this.indexesByStore[candidateStore.name] === undefined) {
				this.indexesByStore[candidateStore.name] = [];
				this.indexesByStore[candidateStore.name].ref = candidateStore.ref;
				++(this.storeCount);
			}
			
			this.indexesByStore[candidateStore.name].push(indexRequest.name);
		}
		return !!candidateStore;
	};

	/**
	 * Open all the indexes added to the StoreManager.
	 * Once all the indexes were opened, the callback function is called.
	 * @param callback the function to call when everything is opened (called with false if some index fails to open)
	 */
	this.openIndexes = function(callback, errorCallback) {
		if (this.storeCount === 0) {
			return callback();
		}
        errorCallback = errorCallback || function(){};
		var synchro = fullproof.make_synchro_point(callback, this.storeCount);
		
		for (var k in this.indexesByStore) {
			var store = new this.indexesByStore[k].ref();

            var arr = this.indexesByStore[k];
			var reqIndexes = [];
			var storeCapabilities = new fullproof.Capabilities(); // .setDbName(this.dbName);
			var size = 0;
			for (var i=0; i<arr.length; ++i) {
				var index = this.indexes[arr[i]];
				reqIndexes.push(index.req);
                if (index.req.capabilities &&  index.req.capabilities.getDbSize()) {
				    size += Math.max(index.req.capabilities.getDbSize(),0);
                }
				if (index.req.capabilities && index.req.capabilities.getDbName()) {
					storeCapabilities.setDbName(index.req.capabilities.getDbName());
				}
			}
            if (size != 0) {
                storeCapabilities.setDbSize(size);
            }

			var self = this;
            store.open(storeCapabilities, reqIndexes, function(indexArray) {
                if (indexArray && indexArray.length>0) {
					for (var i=0; i<indexArray.length; ++i) {
						var index = indexArray[i];
						index.parentStore = store;
						index.storeName = k;
						self.indexes[index.name].index = index;
					}
					synchro(store);
				} else {
					errorCallback();
				}
			}, errorCallback);
		}
	};
	
	/**
	 * Returns information relative to the index
	 * @param indexName the index name
	 */
	this.getInfoFor = function(indexName) {
		return this.indexes[indexName];
	};

	this.getIndex = function(name) {
		return this.indexes[name].index;
	};
	
	this.forEach = function(callback) {
		for (var k in this.indexes) {
			callback(k, this.indexes[k].index);
		}
	}
	
};
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};

/**
 * An object that associates a value and a numerical score
 * @constructor
 */
fullproof.ScoredElement = function (value, score) {
    if (!(this instanceof fullproof.ScoredElement)) {
        return new fullproof.ScoredElement(value, score);
    }
    this.value = value;
    this.score = score === undefined ? 1.0 : score;
};

fullproof.ScoredElement.prototype.toString = function() {
	return "["+this.value+"|"+this.score+"]";
};
fullproof.ScoredElement.prototype.getValue = function () {
    return this.value;
};
fullproof.ScoredElement.prototype.getScore = function () {
    return this.score;
};

fullproof.ScoredElement.comparatorObject = {
		lower_than: function(a,b) {
			return a.value<b.value;
		},
		equals: function(a,b) {
			return a.value==b.value;
		}
	};
fullproof.ScoredElement.prototype.comparatorObject = fullproof.ScoredElement.comparatorObject;

fullproof.ScoredElement.mergeFn = function(a,b) {
	return new fullproof.ScoredElement(a.value, a.score + b.score);
};

/**
 * Associates a key (typically a word), a value, and a score.
 * @constructor
 * @extends {fullproof.ScoredElement}
 */
fullproof.ScoredEntry = function (key, value, score) {
    if (!(this instanceof fullproof.ScoredEntry)) {
        return new fullproof.ScoredEntry(key, value, score);
    }
    this.key = key;
    this.value = value;
    this.score = score === undefined ? 1.0 : score;
};
fullproof.ScoredEntry.prototype = new fullproof.ScoredElement();
fullproof.ScoredEntry.comparatorObject = fullproof.ScoredElement.comparatorObject;
fullproof.ScoredEntry.prototype.getKey = function() { return this.key; };
fullproof.ScoredEntry.prototype.toString = function () {
    return "[" + this.key + "=" + this.value + "|" + this.score + "]";
};



/**
 * Creates a synchronization point. Return a function that collects
 * results and calls its callback argument with the collected data.
 * The synchronization point will trigger the callback when either (a) it
 * receives a predetermined number of results (expected argument >= 1), or
 * (b) it receives a false boolean value as argument (expected has to be
 * either undefined or false).

 * Note that the callback function will never be called more than once.

 * @param {function} callback the function to call when the synchronization point is reached
 * @param {number} expected defines the synchronization point. If this is a number, the synchronization is
 * triggered when the function returned is called this number of times. If this is set undefined, the sync is
 * triggered when this function returned is called with a single argument {boolean} false.
 * @param debug if defined, some debugging information are printed to the console, if it exists.
 */
fullproof.make_synchro_point = function (callback, expected, debug, thrown_if_false) {
    var count = 0;
    var results = [];
    var callbackCalled = false;
    return function (res) {
        if (thrown_if_false !== undefined && res === false) {
            throw thrown_if_false;
        }
        if (expected === false || expected === undefined) {
            if (res === false) {
                if (callbackCalled === false) {
                    callbackCalled = true;
                    callback(results);
                }
            } else {
                results.push(res);
            }
        } else {

            ++count;
            results.push(res);
            if (debug && console && console.log) {
                console.log("synchro point " + (typeof debug == "string" ? debug + ": " : ": ") + count + " / " + expected);
            }
            if (count == expected) {
                if (callbackCalled === false) {
                    callbackCalled = true;
                    callback(results);
                }
            }
        }
    };
};

fullproof.call_new_thread = function() {
	var args = Array.prototype.slice.call(arguments);
	setTimeout(function() {
		if (args.length>0) {
			var func = args.shift();
			func.apply(this, args);
		}
	}, 1);
};

/**
 * Creates and returns a function that, when called, calls the callback argument, with any number
 * of arguments.
 * @param {function} callback a function reference to call when the created function is called
 * @param {...*} varargs any number of arguments that will be applied to the callback function, when called.
 */
fullproof.make_callback = function(callback) {
	var args = Array.prototype.slice.call(arguments, 1);
	return function() {
		if (callback) {
			callback.apply(this, args);
		}
	}
};

fullproof.thrower = function (e) {
    return function () {
        throw e;
    };
};

fullproof.bind_func = function(object, func) {
	return function() {
		var args = Array.prototype.slice.apply(arguments);
		return func.apply(object, args);
	}
};

fullproof.filterObjectProperties = function (array_of_object, property) {
    if (array_of_object instanceof fullproof.ResultSet) {
        array_of_object = array_of_object.getDataUnsafe();
    }
    var result = [];
    for (var i = 0, max = array_of_object.length; i < max; ++i) {
        result.push(array_of_object[i][property]);
    }
    return result;
};


/**
 * Represents a request for the creation of an index. Provided are the name of the index,
 * suitable for use by any store, the capabilities required for this index, and the
 * initializer for its data.
 */
fullproof.IndexRequest = function(name, capabilities, initializer) {
	if (!(this instanceof fullproof.IndexRequest)) {
		return new fullproof.IndexRequest(name, capabilities, initializer);
	}
	this.name = name;
	this.capabilities = capabilities;
	this.initializer = initializer;
};

fullproof.isFunction = function (f) {
    return (typeof f == "function") || (f instanceof Function);
};

/**
 * An HashMap structure that uses a javascript object to store its data, and prefixes all the keys
 * with a '$' to avoid name conflict with object properties.
 * @constructor
 */
fullproof.HMap = function() {
}

fullproof.HMap.prototype.put = function(k,v) {
    this["$"+k] = v;
}
fullproof.HMap.prototype.putInArray = function(k,v) {
    var $k = "$"+k;
    if (!this[$k] || this[$k].constructor !== Array) {
        this[$k] = [];
    }
    this[$k].push(v);
}
fullproof.HMap.prototype.get = function(k) {
    return this["$"+k];
}
fullproof.HMap.prototype.forEach = function(func) {
    for (var k in this) {
       if ("$" === k[0]) {
           func(k.substring(1));
       }
    }
}
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

var fullproof = fullproof || {};
fullproof.store = fullproof.store || {};
(function(window) {
    "use strict";

    try {
        fullproof.store.indexedDB =  indexedDB || window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB || window.msIndexedDB;
        fullproof.store.IDBTransaction = IDBTransaction || window.IDBTransaction || window.webkitIDBTransaction || window.mozIDBTransaction || window.msIDBTransaction || {};
        fullproof.store.READWRITEMODE  = fullproof.store.IDBTransaction.readwrite || fullproof.store.IDBTransaction.READ_WRITE || "readwrite";
    } catch(e) {
        fullproof.store.indexedDB = window.indexedDB;
        fullproof.store.IDBTransaction = window.IDBTransaction;
        fullproof.store.READWRITEMODE = "readwrite";
    }

    //
    // A few methods for dealing with indexedDB stores
    //
    function install_on_request(req, success, error) {
        req.onsuccess = success;
        req.onerror = error;
        return req;
    }

    function getOrCreateObjectStore(tx, name, parameter) {
        if (tx.db.objectStoreNames.contains(name)) {
            return tx.objectStore(name);
        } else {
            return tx.db.createObjectStore(name, parameter);
        }
    }

    function setObject(store, object, callback, error) {
        var req = store.put(object);
        install_on_request(req, fullproof.make_callback(callback, object), error);
    }

    function getOrCreateObject(store, keyValue, defaultValue, callback, error) {

        function create() {
            if (fullproof.isFunction(defaultValue)) {
                defaultValue = defaultValue();
            }
            setObject(store, defaultValue, callback, error);
        }
        try {
            var req = store.get(keyValue);
        } catch (e) {
            console && console.log && console.log(e);
            error(e);
        }

        req.onsuccess = function(ev) {
            if (ev.target.result === undefined) {
                if (defaultValue !== undefined) {
                    create();
                } else {
                    error();
                }
            } else {
                callback(req.result);
            }
        };
        req.onerror = create;
    }

    /**
     * An IndexedDBIndex object manages an inverted index in an IndexedDB store.
     *
     * @param database the database associated to this index
     * @param storeName the name of the object store
     * @constructor
     */
    function IndexedDBIndex(parent, database, indexName, comparatorObject, useScore) {
        this.parent = parent;
        this.database = database;
        this.name = indexName;
        this.comparatorObject = comparatorObject;
        this.useScore = useScore;
        this.internalComparator = useScore?function(a,b) {
            return this.comparatorObject(a.value,b.value);
        }:function(a,b) {
            return this.comparatorObject(a,b);
        };
    }

    IndexedDBIndex.prototype.clear = function (callback) {
        callback = callback || function(){};
        var self = this;
        var wrongfunc = fullproof.make_callback(callback, false);
        var tx = this.database.transaction([this.name, this.parent.metaStoreName], fullproof.store.READWRITEMODE);
        var metastore = tx.objectStore(this.parent.metaStoreName);
        install_on_request(metastore.put({id:this.name, init:false}), function () {
            fullproof.call_new_thread(function () {
                var tx = self.database.transaction([self.name], fullproof.store.READWRITEMODE);
                var store = tx.objectStore(self.name);
                var req = store.clear();
                install_on_request(req, fullproof.make_callback(callback, true), wrongfunc);
            });
        }, wrongfunc);
    };

    IndexedDBIndex.prototype.inject = function(word, value, callback) {
        var tx = this.database.transaction([this.name], fullproof.store.READWRITEMODE);
        var store = tx.objectStore(this.name);
        var self = this;
        var result = false;
        getOrCreateObject(store, word, function() { return {key:word,v:[]} }, function(obj) {
            var rs = new fullproof.ResultSet(self.comparatorObject).setDataUnsafe(obj.v);
            if (value instanceof fullproof.ScoredElement) {
                if (self.useScore) {
                    rs.insert({v:value.value, s:value.score});
                } else {
                    rs.insert(value.value);
                }
            } else {
                rs.insert(value);
            }
            obj.v = rs.getDataUnsafe();
            setObject(store, obj, callback, fullproof.make_callback(callback, false));
        }, fullproof.make_callback(callback,false));
    };

    var storedObjectComparator_score = {
        lower_than: function(a, b) {
            return (a.v?a.v:a)<(b.v? b.v:b);
        },
        equals: function(a,b) {
            return (a.v?a.v:a)===(b.v? b.v:b);
        }
    };

    function createMapOfWordsToResultSet(self, wordArray, valuesArray, offset, count, resultPropertiesAsArray) {
        var result = new fullproof.HMap();
        for (; offset < count; ++offset) {
            var word = wordArray[offset];
            var value = valuesArray[offset];

            if (result.get(word) === undefined) {
                result.put(word, new fullproof.ResultSet(storedObjectComparator_score));
                resultPropertiesAsArray.push(word);
            }
            if (value instanceof fullproof.ScoredElement) {
                if (self.useScore) {
                    var rs = result.get(word);
                    rs.insert({v:value.value, s:value.score});
                } else {
                    result.get(word).insert(value.value);
                }
            } else {
                result.get(word).insert(value);
            }
        }
        return result;
    }

    function storeMapOfWords(self, store, words, data, callback, offset, max) {
        if (words.length>0 && offset < max) {
            var word = words[offset];
            var value = data.get(word);
            getOrCreateObject(store, word, function() { return {key:word,v:[]};}, function(obj) {
                var rs = new fullproof.ResultSet(self.comparatorObject).setDataUnsafe(obj.v);
                rs.merge(value);
                obj.v = rs.getDataUnsafe();
                setObject(store, obj, function() {
                    storeMapOfWords(self, store, words, data, callback, offset+1, max);
                }, function() { /// callback(false);
                });
            });
        } else {
            // callback(true);
        }
    }

    IndexedDBIndex.prototype.injectBulk = function (wordArray, valuesArray, callback, progress) {
        var self = this;
        if (wordArray.length !== valuesArray.length) {
            throw "Can't injectBulk, arrays length mismatch";
        }

        var batchSize = 100;

        var words = [];
        var data = createMapOfWordsToResultSet(this, wordArray, valuesArray, 0, wordArray.length, words);

        function storeData(self, words, data, callback, progress, offset) {
            if (progress) {
                progress(offset / words.length);
            }
            var tx = self.database.transaction([self.name], fullproof.store.READWRITEMODE);
            var inError = false;
            tx.oncomplete = function() {
                if (offset+batchSize < words.length) {
                    fullproof.call_new_thread(storeData, self, words, data, callback, progress, offset + batchSize);
                } else {
                    fullproof.call_new_thread(callback, true);
                }
            };
            tx.onerror = function() { callback(false);};
            var store = tx.objectStore(self.name);

            for (var i=offset, max=Math.min(words.length,offset+batchSize); i<max; ++i) {
                var word = words[i];
                (function(word,value) {
                    getOrCreateObject(store, word, function() { return {key:word,v:[]};}, function(obj) {
                        var rs = new fullproof.ResultSet(self.comparatorObject).setDataUnsafe(obj.v);
                        rs.merge(value);
                        obj.v = rs.getDataUnsafe();
                        setObject(store, obj, function() { }, function() { inError = true; });
                    });
                })(word,data.get(word));
            }
        }

        if (words.length > 0) {
            storeData(this, words, data, callback, progress, 0);
        } else {
            callback(true);
        }
    };


    IndexedDBIndex.prototype.lookup = function(word, callback) {
        var tx = this.database.transaction([this.name]);
        var store = tx.objectStore(this.name);
        var self = this;
        getOrCreateObject(store, word, undefined, function(obj) {
            if (obj && obj.v) {
                var rs = new fullproof.ResultSet(self.comparatorObject);
                for (var i=0,max=obj.v.length; i<max; ++i) {
                    var o = obj.v[i];
                    if (self.useScore) {
                        rs.insert(new fullproof.ScoredEntry(word, o.v, o.s));
                    } else {
                        rs.insert(o);
                    }
                }
                callback(rs);
            } else {
                callback(new fullproof.ResultSet(self.comparatorObject));
            }
        }, function() { callback(new fullproof.ResultSet(self.comparatorObject)); });
    };

    /**
     * IndexedDBStore stores the inverted indexes in a local IndexedDB database.
     * @constructor
     */
    fullproof.store.IndexedDBStore = function (version) {

        this.database = null;
        this.meta = null;
        this.metaStoreName = "fullproof_metatable";
        this.stores = {};
        this.opened = false;
        this.dbName = "fullproof";
        this.dbSize = 1024 * 1024 * 5;
        this.dbVersion = version || "1.0";
    };
    fullproof.store.IndexedDBStore.storeName = "MemoryStore";
    fullproof.store.IndexedDBStore.getCapabilities = function () {
        return new fullproof.Capabilities().setStoreObjects(false).setVolatile(false).setAvailable(fullproof.store.indexedDB != null).setUseScores([true, false]);
    };

    fullproof.store.IndexedDBStore.prototype.setOptions = function(params) {
        this.dbSize = params.dbSize||this.dbSize;
        this.dbName = params.dbName||this.dbName;
        return this;
    };

    /**
     * Creates the missing indexes (object stores) in the database
     * @param database a valid IDBDatabase object
     * @param indexRequestArray an array of fullproof.IndexRequest objects
     * @param metaStoreName the name of the index that stores the metadata
     * @private
     */
    function createStores(database, indexRequestArray, metaStoreName) {
        if (!database.objectStoreNames.contains(metaStoreName)) {
            database.createObjectStore(metaStoreName, {keyPath: "id"});
        }
        for (var i=0; i<indexRequestArray.length; ++i) {
            if (!database.objectStoreNames.contains(indexRequestArray[i].name)) {
                database.createObjectStore(indexRequestArray[i].name, {keyPath: "key"});
            }
        }
    }

    fullproof.store.IndexedDBStore.prototype.open = function(caps, reqIndexArray, callback, errorCallback) {
        if (caps.getDbName() !== undefined) {
            this.dbName = caps.getDbName();
        }
        if (caps.getDbSize() !== undefined) {
            this.dbSize = caps.getDbSize();
        }

        var updated = false;
        var self = this;

        var indexArrayResult = [];

        function setupIndexes(self) {
            for (var i=0; i<self.indexRequests.length; ++i) {
                var ireq =self.indexRequests[i];
                var compObj = ireq.capabilities.getComparatorObject()?ireq.capabilities.getComparatorObject():(self.useScore?fullproof.ScoredElement.comparatorObject:undefined);
                var index = new IndexedDBIndex(self, self.database, ireq.name, compObj, ireq.capabilities.getUseScores());
                self.stores[ireq.name] = index;
                indexArrayResult.push(index);
            }
        }

        function callInitializerIfNeeded(database, self, indexRequestArray, callback, errorCallback) {
            if (indexRequestArray.length == 0) {
                return callback(true);
            }

            var tx = database.transaction([self.metaStoreName], fullproof.store.READWRITEMODE);
            var metastore = tx.objectStore(self.metaStoreName);
            var ireq = indexRequestArray.shift();
            getOrCreateObject(metastore, ireq.name, {id: ireq.name, init: false},
                function(obj) {
                    if (obj.init == false && ireq.initializer) {
                        var initIndex = self.getIndex(ireq.name);
                        fullproof.call_new_thread(function() {
                            initIndex.clear(function() {
                                ireq.initializer(self.getIndex(ireq.name), function() {
                                    fullproof.call_new_thread(callInitializerIfNeeded, database, self, indexRequestArray, callback, errorCallback);
                                    fullproof.call_new_thread(function() {
                                        var tx = database.transaction([self.metaStoreName], fullproof.store.READWRITEMODE);
                                        var metastore = tx.objectStore(self.metaStoreName);
                                        obj.init = true;
                                        install_on_request(metastore.put(obj), function(){}, function(){});;
                                    });
                                });
                            });
                        });
                    } else {
                        fullproof.call_new_thread(callInitializerIfNeeded, database, self, indexRequestArray, callback, errorCallback);
                    }
                }, errorCallback);
        }

        function checkInit(self, database, indexRequestArray, callback, errorCallback) {
            createStores(database, indexRequestArray, self.metaStoreName);
            setupIndexes(self);
            // callInitializerIfNeeded(database, self, [].concat(indexRequestArray), callback, errorCallback);
            fullproof.call_new_thread(callInitializerIfNeeded, database, self, [].concat(indexRequestArray), callback, errorCallback);
        }

        this.indexRequests = reqIndexArray;

        var openRequest = fullproof.store.indexedDB.open(this.dbName, this.dbVersion);
        openRequest.onerror = function() {
            errorCallback();
        };
        openRequest.onsuccess = function(ev) {
            self.database = ev.result || ev.target.result;

            if (self.database.version !== undefined && self.database.setVersion && self.database.version != self.dbVersion) {
                var versionreq = self.database.setVersion(self.dbVersion);
                versionreq.onerror = fullproof.make_callback(errorCallback, "Can't change version with setVersion(" +self.dbVersion+")");
                versionreq.onsuccess = function(ev) {
                    createStores(self.database, reqIndexArray, self.metaStoreName);
                    checkInit(self, self.database, self.indexRequests,
                        function() {
                            callback(indexArrayResult);
                        }, errorCallback);
                }
            } else {
                checkInit(self, self.database, self.indexRequests, fullproof.make_callback(callback, indexArrayResult), errorCallback);
            }
        };
        openRequest.onupgradeneeded = function(ev) {
            createStores(ev.target.result, reqIndexArray, self.metaStoreName);
            updated = true;
        };

    };


    fullproof.store.IndexedDBStore.prototype.close = function (callback) {
        callback();
    };

    fullproof.store.IndexedDBStore.prototype.getIndex = function(name) {
        return this.stores[name];
    };

})(typeof window === 'undefined' ? {} : window);
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};
fullproof.store = fullproof.store||{};

(function() {
"use strict";

	function MemoryStoreIndex() {
		this.data= {};
		this.comparatorObject = null;
		this.useScore= false;
	}
	
	fullproof.store.MemoryStore = function() {
		
		if (!(this instanceof fullproof.store.MemoryStore)) {
			return new fullproof.store.MemoryStore(comparatorObject);
		}		
		
		this.indexes = {};
		return this;
	};

	fullproof.store.MemoryStore.getCapabilities = function () {
        return new fullproof.Capabilities().setStoreObjects([true, false]).setVolatile(true).setAvailable(true).setUseScores([true, false]);
    };
	fullproof.store.MemoryStore.storeName = "MemoryStore";

	function openStore(parameters, callback) {
        parameters=parameters;
		// ignore parameters
		if (callback) {
			callback(this);
		}
	}

	function openIndex(store, name, parameters, initializer, callback) {
		var index = new MemoryStoreIndex();
		var useScore = parameters.getUseScores()!==undefined?(parameters.getUseScores()):false;
		index.comparatorObject = parameters.getComparatorObject()?parameters.getComparatorObject():(useScore?fullproof.ScoredElement.comparatorObject:undefined);
		index.useScore = useScore;
        index.name = name;
		store.indexes[name] = index;
		if (initializer) {
			initializer(index, function() {
				callback(index);
			});
		} else {
			callback(index);
		}
		return index;
	}

	fullproof.store.MemoryStore.prototype.open = function(caps, reqIndexArray, callback, errorCallback) {
		var self = this;
		openStore(caps, function() {
			var synchro = fullproof.make_synchro_point(function(result) {
				callback(result);
			}, reqIndexArray.length);
			for (var i=0, max=reqIndexArray.length; i<max; ++i) {
				var requestIndex = reqIndexArray[i];
				openIndex(self, requestIndex.name, requestIndex.capabilities, requestIndex.initializer, synchro);
			}
		});
	};
	
	fullproof.store.MemoryStore.prototype.getIndex = function(name) {
		return this.indexes[name];
	};

	
	fullproof.store.MemoryStore.prototype.close = function(callback) {
		this.indexes = {};
		callback(this);
	};
	
	MemoryStoreIndex.prototype.clear = function (callback) {
        this.data = {};
        if (callback) {
            callback(true);
        }
        return this;
    };
	
	/**
	 * Inject data. Can be called as follows:
	 * memstoreInstance.inject("someword", 31321321, callbackWhenDone);
	 * memstoreInstance.inject("someword", new fullproof.ScoredElement(31321321, 1.0), callbackWhenDone);
	 * 
	 * When score is not set, and store is configured to store a score, then it is saved as undefined.
	 * When the score is set, and the store is configured not to store a score, it raises an exception
	 */

	MemoryStoreIndex.prototype.inject = function(key, value, callback) {
		if (!this.data[key]) {
			this.data[key] = new fullproof.ResultSet(this.comparatorObject);
		}
		if (this.useScore === false && value instanceof fullproof.ScoredElement) {
			this.data[key].insert(value.value);
		} else {
			this.data[key].insert(value);
		}

		if (callback) {
			callback(key,value);
		}
		
		return this;
	};

	MemoryStoreIndex.prototype.injectBulk = function(keyArray, valueArray, callback, progress) {
		for (var i=0; i<keyArray.length && i<valueArray.length; ++i) {
            if (i%1000 === 0 && progress) {
                progress(i / keyArray.length);

            }
			this.inject(keyArray[i], valueArray[i]);
		}
		if (callback) {
			callback(keyArray,valueArray);
		}
		return this;
	};

	
	MemoryStoreIndex.prototype.lookup = function(word, callback) {
		callback(this.data[word]?this.data[word].clone():new fullproof.ResultSet);
		return this;
	};


})();
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};
fullproof.store = fullproof.store||{};

(function(window) {
"use strict";

	function WebSQLStoreIndex() {
		this.db = null;
		this.store = null;
		this.tableName = null;
		this.comparatorObject = null;
		this.useScore = false;
		this.opened = false;

    }

	function sql_table_exists_or_empty(tx, tablename, callback) {
		tx.executeSql("SELECT * FROM " + tablename + " LIMIT 1,0", [], function(tx,res) {
			if (res.rows.length == 1) {
				callback(true);
			} else {
				callback(false);
			}
		}, fullproof.make_callback(callback, false));
	};
	
	function MetaData(store, callback, errorCallback) {
		this.tablename = "fullproofmetadata";
		var meta = this;
		
		this.createIndex = function(name, successCallback, errorCallback) {
			var error = fullproof.make_callback(errorCallback);
			var tablename = meta.tablename;
			store.db.transaction(function(tx) {
				sql_table_exists_or_empty(tx, name, function(exists) {
					if (!exists) {
						tx.executeSql("CREATE TABLE IF NOT EXISTS "+ name +" (id NCHAR(48), value, score)", [], 
									function() {
										store.db.transaction(function(tx) {				
											tx.executeSql("CREATE INDEX IF NOT EXISTS "+ name +"_indx ON " + name + " (id)", [], function() {
												tx.executeSql("INSERT OR REPLACE INTO " + meta.tablename + " (id, initialized) VALUES (?,?)", [name, false], 
														fullproof.make_callback(successCallback, true),
														error);
											}, error);
										});
									}, error);
					} else {
						successCallback(true);
					}
				});
			});
		};

		this.loadMetaData = function(callback) {
			store.db.transaction(function(tx) {
				tx.executeSql("SELECT * FROM " + meta,tablename + " WHERE id=?", [tableName], function(tx,res) {
					var result = {};
					for (var i=0; i<res.rows.length; ++i) {
						var line = res.rows.item(i);
						result[line.id] = {name: line.id, initialized: line.initialized, ctime: line.ctime, version: line.version};
					}
					callback(result);
				}, fullproof.make_callback(callback, {}));
			});
		};
		
		this.isInitialized = function(tableName, callback) {
			store.db.transaction(function(tx) {
				tx.executeSql("SELECT * FROM " + meta.tablename + " WHERE id=?", [tableName], function(tx,res) {
					if (res.rows.length == 1) {
						var line = res.rows.item(0);
						callback("true" == line.initialized);
					} else {
						callback(false)
					}
				}, fullproof.make_callback(callback, false));
			});
		};
		
		this.setInitialized = function(tablename, value, callback) {
			store.db.transaction(function(tx) {
				tx.executeSql("INSERT OR REPLACE INTO " + meta.tablename + " (id, initialized) VALUES (?,?)", [tablename, value?"true":"false"],
						fullproof.make_callback(callback, true),
						fullproof.make_callback(callback, false));
			});
		};
		
		this.getIndexSize = function(name, callback) {
			store.db.transaction(function(tx) {
				tx.executeSql("SELECT count(*) AS cnt FROM " + name, [], function(tx,res) {
					if (res.rows.length == 1) {
						var line = res.rows.item(0);
						if (line.cnt !== undefined) {
							return callback(line.cnt);
						}
					}
					callback(false);
				}, function() {
					callback(false);
				});
			});
		};

		this.eraseMeta = function(callback) {
			var self = this;
			meta.loadMetaData(function(data) {
				store.db.transaction(function(tx) {
					var count = 0;
					for (var k in data) { ++count; }
					var synchro = fullproof.make_synchro_point(function() {
						tx.executeSql("DROP TABLE IF EXISTS "+ meta.tablename, [], fullproof.make_callback(errorCallback,true), fullproof.make_callback(errorCallback,false));
					}, count);
					for (var k in data) {
						tx.executeSql("DROP TABLE IF EXISTS " + k);
					}
				});
			});
		};
		
		store.db.transaction(function(tx) {
			tx.executeSql("CREATE TABLE IF NOT EXISTS "+ meta.tablename +" (id VARCHAR(52) NOT NULL PRIMARY KEY, initialized, version, ctime)", [], 
				function() {
					callback(store);
				}, fullproof.make_callback(errorCallback,false))});
	}

	/**
	 * @constructor
	 */
	fullproof.store.WebSQLStore = function(){
		if (!(this instanceof fullproof.store.WebSQLStore)) {
			return new fullproof.store.WebSQLStore();
		}
				
		this.internal_init = function () {
            this.db = null;
            this.meta = null;
            this.tables = {};
            this.indexes = {};
            this.opened = false;
            this.dbName = "fullproof";
            this.dbSize = 1024 * 1024 * 5;
        };
		this.internal_init();
	};
	
	fullproof.store.WebSQLStore.getCapabilities = function () {
        try {
            return new fullproof.Capabilities().setStoreObjects(false).setVolatile(false).setAvailable(window.openDatabase).setUseScores([true, false]);
        } catch (e) {
            return new fullproof.Capabilities().setAvailable(false);
        }
    };
	fullproof.store.WebSQLStore.storeName = "WebsqlStore";

	
	fullproof.store.WebSQLStore.prototype.setOptions = function(params) {
		this.dbSize = params.dbSize||this.dbSize;
		this.dbName = params.dbName||this.dbName;
        return this;
	};

	function openIndex(store, name, parameters, initializer, callback, errorCallback) {
		if (store.opened == false || !store.meta) {
			return callback(false);
		}
		
		parameters = parameters||{};
		var index = new WebSQLStoreIndex();
		index.store = store;
		var useScore = parameters.getUseScores()!==undefined?(parameters.getUseScores()):false;
		
		index.db = store.db;
		index.tableName = index.name = name;
		index.comparatorObject = parameters.getComparatorObject()?parameters.getComparatorObject():(useScore?fullproof.ScoredElement.comparatorObject:undefined);
		index.useScore = useScore;
		
		var self = store;
		store.meta.isInitialized(name, function(isInit) {
			if (isInit) {
				return callback(index);
			} else {
				self.meta.createIndex(name, function() {
					self.indexes[name] = index;
					if (initializer) {
                        fullproof.call_new_thread(function() {
                            index.clear(function() {
                                fullproof.call_new_thread(function() {
                                    initializer(index, function() {
                                        index.opened = true;
                                        self.meta.setInitialized(name, true, fullproof.make_callback(callback, index));
                                    });
                                });
                            });
                        });
					} else {
						callback(index);
					}
				}, errorCallback);
			}
		});				
	}; 

	function openStore(store, parameters, callback) {
		store.opened = false;
        if (parameters.getDbName() !== undefined) {
			store.dbName = parameters.getDbName();
		}
		if (parameters.getDbSize() !== undefined) {
			store.dbSize = parameters.getDbSize();
		}
        try {
            store.db = openDatabase(store.dbName, '1.0', 'javascript search engine', store.dbSize);
        } catch (e) {
            console && console.log && console.log("websql: ERROR in openStore"+ e);
        }
        store.opened = true;
		store.meta = new MetaData(store, function(store) {
            callback(store);
			}, fullproof.make_callback(callback,false));
	};

	
	fullproof.store.WebSQLStore.prototype.open = function(caps, reqIndexArray, callback, errorCallback) {
        var self = this;
		var resultArray = [];
        this.dbName = caps.getDbName() || this.dbName;
        function chainOpenIndex(reqIndexes) {
			if (reqIndexes.length == 0) {
                return callback(resultArray);
			}
            var requestIndex = reqIndexes.shift();
            openIndex(self, requestIndex.name, requestIndex.capabilities, requestIndex.initializer, function(index) {
				resultArray.push(index);
				chainOpenIndex(reqIndexes);
			});
		}

        openStore(this, caps, function(store) {
            var synchro = fullproof.make_synchro_point(callback, reqIndexArray.length);
			var consumedReqIndexes = [].concat(reqIndexArray);
			chainOpenIndex([].concat(reqIndexArray));
		});
	};
	
	fullproof.store.WebSQLStore.prototype.close = function(callback) {
		this.internal_init();
		callback();
	};

	fullproof.store.WebSQLStore.prototype.getIndex = function(name) {
		return this.indexes[name];
	};

	WebSQLStoreIndex.prototype.clear = function(callback) {
		var self = this;
		this.db.transaction(function(tx) {
			tx.executeSql("DELETE FROM "+ self.tableName, [], function() {
				self.store.meta.setInitialized(self.name, false, callback);	
			}, function() {
				fullproof.make_callback(callback, false)();
			});
			
		});
	};

	WebSQLStoreIndex.prototype.inject = function(word, value, callback) {
		var self = this;
		this.db.transaction(function(tx) {
			if (value instanceof fullproof.ScoredElement) {
				tx.executeSql("INSERT OR REPLACE INTO " + self.tableName + " (id,value, score) VALUES (?,?,?)", [word, value.value, value.score], fullproof.make_callback(callback, true), fullproof.make_callback(callback, false));
			} else {
				tx.executeSql("INSERT OR REPLACE INTO " + self.tableName + " (id,value) VALUES (?,?)", [word, value], fullproof.make_callback(callback, true), fullproof.make_callback(callback, false));
			}
		});
	};

	WebSQLStoreIndex.prototype.injectBulk = function(wordArray, valuesArray, callback, progress) {
		var self = this;
		if (wordArray.length != valuesArray.length) {
			throw "Can't injectBulk, arrays length mismatch";
		}
		var batchSize = 100;
		var transactionsExpected = wordArray.length / batchSize + (wordArray%batchSize>0?1:0);
		var bulk_synchro = fullproof.make_synchro_point(callback, undefined, true);
		var totalSize = wordArray.length;

		var processBulk = function(wArray, vArray, offset) {
//			var curWords = wArray.splice(0, batchSize<wArray.length?batchSize:wArray.length);
//			var curValues = vArray.splice(0, batchSize<vArray.length?batchSize:vArray.length);
//			if (curWords.length == 0) {
//				bulk_synchro(false);
//			}

            if (offset >= wArray.length) {
                fullproof.call_new_thread(callback, true);
            }

            var offsetEnd = Math.min(offset + batchSize, wArray.length);
			if (progress && totalSize) {
				progress(offset/totalSize);
			}
			
			var synchronizer = fullproof.make_synchro_point(function() {
				fullproof.call_new_thread(processBulk, wArray, vArray, offsetEnd);
			}, offsetEnd - offset);
			
			self.db.transaction(function(tx) {
				for (var i=offset, end=offsetEnd; i<end; ++i) {
					var value = vArray[i];
					if (value instanceof fullproof.ScoredEntry) {
						if (self.useScore) {
							tx.executeSql("INSERT INTO " + self.tableName + " (id,value, score) VALUES (?,?,?)", [wArray[i], value.value, value.score], synchronizer, function() {
                                // do something...
                            });
						} else {
							tx.executeSql("INSERT INTO " + self.tableName + " (id,value) VALUES (?,?)", [wArray[i], value.value], synchronizer, synchronizer);
						}
					} else {
						if (self.useScore) {
							tx.executeSql("INSERT INTO " + self.tableName + " (id,value, score) VALUES (?,?,?)", [wArray[i], value, 1.0], synchronizer, synchronizer);
						}
						else {
							tx.executeSql("INSERT INTO " + self.tableName + " (id,value) VALUES (?,?)", [wArray[i], value],
									function() {
								synchronizer();
							}, function() {
								synchronizer(true);
							});
						}
					}
				}
			});
		};
		
		processBulk(wordArray, valuesArray, 0);
		
	};
	
	/**
	 * WebSQLStore does not support object storage, only primary values, so we rely
	 * on the sql engine sorting functions. ORDER BY should provide fine results as long as
	 * the datatype of values is consistant.
	 */
	WebSQLStoreIndex.prototype.lookup = function(word, callback) {
		var self = this;
		this.db.transaction(function(tx) {
			tx.executeSql("SELECT * FROM " + self.tableName + " WHERE id=? ORDER BY value ASC", [word],
					function(tx,res) {
                        var result = new fullproof.ResultSet(self.comparatorObject);
						for (var i=0; i<res.rows.length; ++i) {
							var item = res.rows.item(i);
							if (item) {
								if (item.score === null || item.score === undefined || item.score === false) {
									result.insert(item.value);
								} else {
									result.insert(new fullproof.ScoredEntry(item.id, item.value, item.score));
								}
							}
						}
						callback(result);
					}, 
					function() {
						callback(false);
					});
		});
	};
	
})(typeof window === 'undefined' ? {} : window);
/*
 * Copyright 2012 Rodrigo Reyes
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var fullproof = fullproof || {};

(function() {
"use strict";

	function getNewXmlHttpRequest()  {
		if (typeof window.XMLHttpRequest !== "undefined") {
			return new window.XMLHttpRequest;
		} else {
			
		} if (typeof window.ActiveXObject === 'function') {
		        try { return new ActiveXObject('Msxml2.XMLHTTP.6.0'); } catch(e) {}
		        try { return new ActiveXObject('Msxml2.XMLHTTP.3.0'); } catch(e) {}
		        try { return new ActiveXObject('Microsoft.XMLHTTP'); } catch(e) {}
			}
		throw "Error, can't find a suitable XMLHttpRequest object";
	}

	fullproof.DataLoader = function () {

        if (!(this instanceof fullproof.DataLoader)) {
            return new fullproof.DataLoader();
        }

        var loadQueue = [];
        var currentQueue = [];

        this.setQueue = function () {
            for (var i = 0; i < arguments.length; ++i) {
                if (arguments[i].constructor == Array) {
                    loadQueue = loadQueue.concat(arguments[i]);
                } else {
                    loadQueue.push(arguments[i]);
                }
            }
            return this;
        };

        var processQueue = function (completeCallback, fileLoadedCallback, fileFailedCallback) {

            if (currentQueue.length == 0) {
                completeCallback();
                return;
            }

            var element = currentQueue.shift();

            var request = getNewXmlHttpRequest();
            request.onreadystatechange = function () {
                if (request.readyState == 4) {
                    if (request.status != 200) {
                        // Handle error, e.g. Display error message on page
                        if (fileFailedCallback) {
                            fileFailedCallback(element);
                            processQueue(completeCallback, fileLoadedCallback, fileFailedCallback);
                        }
                    } else {
                        var serverResponse = request.responseText;
                        if (fileLoadedCallback) {
                            fileLoadedCallback(serverResponse, element);
                            processQueue(completeCallback, fileLoadedCallback, fileFailedCallback);
                        }
                    }
                }
            };
            request.open("GET", element, true);
            request.send(null);
        };

        this.start = function (completeCallback, fileLoadedCallback, fileFailedCallback) {
            currentQueue = [].concat(loadQueue);
            processQueue(completeCallback, fileLoadedCallback, fileFailedCallback);
        };
    };

//	fullproof.ConfigManager = function(forceCookies) {
//
//		if (!(this instanceof fullproof.ConfigManager)) {
//			return new fullproof.ConfigManager(forceCookies);
//		}
//
//		if (localStorage && !forceCookies) {
//			return new function(configName) {
//				this.set = function(key, value) {
//					localStorage.setItem(configName +"_" + key, value);
//				};
//				this.get = function(key) {
//					return localStorage.getItem(configName + "_" + key);
//				};
//				this.remove = function(key) {
    //					localStorage.removeItem(configName + "_" + key);
//				};
//				return this;
//			};
//		} else {
//			return new function(configName) {
//				this.set = function(key, value) {
//					var date = new Date(Date.now()+(365*24*60*60*1000));
//					document.cookie = configName+"_"+key+"="+value+"; expires=" + date.toGMTString() +"; path=/";
//				};
//				this.get = function (key) {
//                    var fullkey = configName + "_" + key;
//                    var result;
//                    result = (result = new RegExp('(?:^|; )' + encodeURIComponent(fullkey) + '=([^;]*)').exec(document.cookie)) ? (result[1]) : null;
//                    return (result == "") ? null : result;
//                },
//                    this.remove = function (key) {
//                        var date = new Date(Date.now() + (24 * 60 * 60 * 1000));
//                        document.cookie = configName + "_" + key + "= ; expires=" + date.toGMTString() + "; path=/";
//                    };
//				return this;
//			};
//		}
//
//	};

	
})();var net = net||{};net.kornr = net.kornr||{};net.kornr.unicode=net.kornr.unicode||{};
net.kornr.unicode.categ_letters_numbers_data=[[48,57],[65,90],[97,122],170,[178,179],181,[185,186],[188,190],[192,214],[216,246],[248,705],[710,721],[736,740],748
	,750,[880,884],[886,887],[890,893],902,[904,906],908,[910,929],[931,1013],[1015,1153],[1162,1319],[1329,1366],1369
	,[1377,1415],[1488,1514],[1520,1522],[1568,1610],[1632,1641],[1646,1647],[1649,1747],1749,[1765,1766],[1774,1788],1791
	,1808,[1810,1839],[1869,1957],1969,[1984,2026],[2036,2037],2042,[2048,2069],2074,2084,2088,[2112,2136],2208,[2210,2220]
	,[2308,2361],2365,2384,[2392,2401],[2406,2415],[2417,2423],[2425,2431],[2437,2444],[2447,2448],[2451,2472],[2474,2480]
	,2482,[2486,2489],2493,2510,[2524,2525],[2527,2529],[2534,2545],[2548,2553],[2565,2570],[2575,2576],[2579,2600]
	,[2602,2608],[2610,2611],[2613,2614],[2616,2617],[2649,2652],2654,[2662,2671],[2674,2676],[2693,2701],[2703,2705]
	,[2707,2728],[2730,2736],[2738,2739],[2741,2745],2749,2768,[2784,2785],[2790,2799],[2821,2828],[2831,2832],[2835,2856]
	,[2858,2864],[2866,2867],[2869,2873],2877,[2908,2909],[2911,2913],[2918,2927],[2929,2935],2947,[2949,2954],[2958,2960]
	,[2962,2965],[2969,2970],2972,[2974,2975],[2979,2980],[2984,2986],[2990,3001],3024,[3046,3058],[3077,3084],[3086,3088]
	,[3090,3112],[3114,3123],[3125,3129],3133,[3160,3161],[3168,3169],[3174,3183],[3192,3198],[3205,3212],[3214,3216]
	,[3218,3240],[3242,3251],[3253,3257],3261,3294,[3296,3297],[3302,3311],[3313,3314],[3333,3340],[3342,3344],[3346,3386]
	,3389,3406,[3424,3425],[3430,3445],[3450,3455],[3461,3478],[3482,3505],[3507,3515],3517,[3520,3526],[3585,3632]
	,[3634,3635],[3648,3654],[3664,3673],[3713,3714],3716,[3719,3720],3722,3725,[3732,3735],[3737,3743],[3745,3747],3749
	,3751,[3754,3755],[3757,3760],[3762,3763],3773,[3776,3780],3782,[3792,3801],[3804,3807],3840,[3872,3891],[3904,3911]
	,[3913,3948],[3976,3980],[4096,4138],[4159,4169],[4176,4181],[4186,4189],4193,[4197,4198],[4206,4208],[4213,4225],4238
	,[4240,4249],[4256,4293],4295,4301,[4304,4346],[4348,4680],[4682,4685],[4688,4694],4696,[4698,4701],[4704,4744]
	,[4746,4749],[4752,4784],[4786,4789],[4792,4798],4800,[4802,4805],[4808,4822],[4824,4880],[4882,4885],[4888,4954]
	,[4969,4988],[4992,5007],[5024,5108],[5121,5740],[5743,5759],[5761,5786],[5792,5866],[5870,5872],[5888,5900]
	,[5902,5905],[5920,5937],[5952,5969],[5984,5996],[5998,6000],[6016,6067],6103,6108,[6112,6121],[6128,6137],[6160,6169]
	,[6176,6263],[6272,6312],6314,[6320,6389],[6400,6428],[6470,6509],[6512,6516],[6528,6571],[6593,6599],[6608,6618]
	,[6656,6678],[6688,6740],[6784,6793],[6800,6809],6823,[6917,6963],[6981,6987],[6992,7001],[7043,7072],[7086,7141]
	,[7168,7203],[7232,7241],[7245,7293],[7401,7404],[7406,7409],[7413,7414],[7424,7615],[7680,7957],[7960,7965]
	,[7968,8005],[8008,8013],[8016,8023],8025,8027,8029,[8031,8061],[8064,8116],[8118,8124],8126,[8130,8132],[8134,8140]
	,[8144,8147],[8150,8155],[8160,8172],[8178,8180],[8182,8188],[8304,8305],[8308,8313],[8319,8329],[8336,8348],8450,8455
	,[8458,8467],8469,[8473,8477],8484,8486,8488,[8490,8493],[8495,8505],[8508,8511],[8517,8521],8526,[8528,8585]
	,[9312,9371],[9450,9471],[10102,10131],[11264,11310],[11312,11358],[11360,11492],[11499,11502],[11506,11507],11517
	,[11520,11557],11559,11565,[11568,11623],11631,[11648,11670],[11680,11686],[11688,11694],[11696,11702],[11704,11710]
	,[11712,11718],[11720,11726],[11728,11734],[11736,11742],11823,[12293,12295],[12321,12329],[12337,12341],[12344,12348]
	,[12353,12438],[12445,12447],[12449,12538],[12540,12543],[12549,12589],[12593,12686],[12690,12693],[12704,12730]
	,[12784,12799],[12832,12841],[12872,12879],[12881,12895],[12928,12937],[12977,12991],13312,19893,19968,40908
	,[40960,42124],[42192,42237],[42240,42508],[42512,42539],[42560,42606],[42623,42647],[42656,42735],[42775,42783]
	,[42786,42888],[42891,42894],[42896,42899],[42912,42922],[43000,43009],[43011,43013],[43015,43018],[43020,43042]
	,[43056,43061],[43072,43123],[43138,43187],[43216,43225],[43250,43255],43259,[43264,43301],[43312,43334],[43360,43388]
	,[43396,43442],[43471,43481],[43520,43560],[43584,43586],[43588,43595],[43600,43609],[43616,43638],43642,[43648,43695]
	,43697,[43701,43702],[43705,43709],43712,43714,[43739,43741],[43744,43754],[43762,43764],[43777,43782],[43785,43790]
	,[43793,43798],[43808,43814],[43816,43822],[43968,44002],[44016,44025],44032,55203,[55216,55238],[55243,55291]
	,[63744,64109],[64112,64217],[64256,64262],[64275,64279],64285,[64287,64296],[64298,64310],[64312,64316],64318
	,[64320,64321],[64323,64324],[64326,64433],[64467,64829],[64848,64911],[64914,64967],[65008,65019],[65136,65140]
	,[65142,65276],[65296,65305],[65313,65338],[65345,65370],[65382,65470],[65474,65479],[65482,65487],[65490,65495]
	,[65498,65500],[65536,65547],[65549,65574],[65576,65594],[65596,65597],[65599,65613],[65616,65629],[65664,65786]
	,[65799,65843],[65856,65912],65930,[66176,66204],[66208,66256],[66304,66334],[66336,66339],[66352,66378],[66432,66461]
	,[66464,66499],[66504,66511],[66513,66517],[66560,66717],[66720,66729],[67584,67589],67592,[67594,67637],[67639,67640]
	,67644,[67647,67669],[67672,67679],[67840,67867],[67872,67897],[67968,68023],[68030,68031],68096,[68112,68115]
	,[68117,68119],[68121,68147],[68160,68167],[68192,68222],[68352,68405],[68416,68437],[68440,68466],[68472,68479]
	,[68608,68680],[69216,69246],[69635,69687],[69714,69743],[69763,69807],[69840,69864],[69872,69881],[69891,69926]
	,[69942,69951],[70019,70066],[70081,70084],[70096,70105],[71296,71338],[71360,71369],[73728,74606],[74752,74850]
	,[77824,78894],[92160,92728],[93952,94020],94032,[94099,94111],[110592,110593],[119648,119665],[119808,119892]
	,[119894,119964],[119966,119967],119970,[119973,119974],[119977,119980],[119982,119993],119995,[119997,120003]
	,[120005,120069],[120071,120074],[120077,120084],[120086,120092],[120094,120121],[120123,120126],[120128,120132],120134
	,[120138,120144],[120146,120485],[120488,120512],[120514,120538],[120540,120570],[120572,120596],[120598,120628]
	,[120630,120654],[120656,120686],[120688,120712],[120714,120744],[120746,120770],[120772,120779],[120782,120831]
	,[126464,126467],[126469,126495],[126497,126498],126500,126503,[126505,126514],[126516,126519],126521,126523,126530
	,126535,126537,126539,[126541,126543],[126545,126546],126548,126551,126553,126555,126557,126559,[126561,126562],126564
	,[126567,126570],[126572,126578],[126580,126583],[126585,126588],126590,[126592,126601],[126603,126619],[126625,126627]
	,[126629,126633],[126635,126651],[127232,127242],131072,173782,173824,177972,177984,178205,[194560,195101]];
;
var net = net||{};net.kornr = net.kornr||{};net.kornr.unicode=net.kornr.unicode||{};
net.kornr.unicode.norm_lowercase_nomark_data=[[65,90,'R',32],[160,168,'A',32],[170,97],[175,32],[178,179,'R',-128],[180,32],[181,956],[184,32],[185,49],[186,111],
	[188,[49, 8260, 52]],[189,[49, 8260, 50]],[190,[51, 8260, 52]],[192,197,'A',97],[198,230],[199,99],[200,203,'A',101],
	[204,207,'A',105],[208,240],[209,210,'R',-99],[211,214,'A',111],[216,248],[217,220,'A',117],[221,121],[222,254],
	[224,229,'A',97],[231,99],[232,235,'A',101],[236,239,'A',105],[241,242,'R',-131],[243,246,'A',111],[249,252,'A',117],
	[253,255,'A',121],[256,261,'A',97],[262,269,'A',99],[270,271,'A',100],[272,273],[274,283,'A',101],[284,291,'A',103],
	[292,293,'A',104],[294,295],[296,304,'A',105],[306,[105, 106]],[307,[105, 106]],[308,309,'A',106],[310,311,'A',107],
	[313,318,'A',108],[319,[108, 183]],[320,[108, 183]],[321,322],[323,328,'A',110],[329,[700, 110]],[330,331],
	[332,337,'A',111],[338,339],[340,345,'A',114],[346,353,'A',115],[354,357,'A',116],[358,359],[360,371,'A',117],
	[372,373,'A',119],[374,376,'A',121],[377,382,'A',122],[383,115],[385,595],[386,388,'R',1],[390,596],[391,392],
	[393,394,'R',205],[395,396],[398,477],[399,601],[400,603],[401,402],[403,608],[404,611],[406,617],[407,616],[408,409],
	[412,623],[413,626],[415,629],[416,417,'A',111],[418,420,'R',1],[422,640],[423,424],[425,643],[428,429],[430,648],
	[431,432,'A',117],[433,434,'R',217],[435,437,'R',1],[439,658],[440,444,'R',1],[452,[100, 382]],[453,[100, 382]],
	[454,[100, 382]],[455,[108, 106]],[456,[108, 106]],[457,[108, 106]],[458,[110, 106]],[459,[110, 106]],[460,[110, 106]],
	[461,462,'A',97],[463,464,'A',105],[465,466,'A',111],[467,468,'A',117],[469,476,'A',252],[478,479,'A',228],
	[480,481,'A',551],[482,483,'A',230],[484,485],[486,487,'A',103],[488,489,'A',107],[490,491,'A',111],[492,493,'A',491],
	[494,495,'A',658],[496,106],[497,[100, 122]],[498,[100, 122]],[499,[100, 122]],[500,501,'A',103],[502,405],[503,447],
	[504,505,'A',110],[506,507,'A',229],[508,509,'A',230],[510,511,'A',248],[512,515,'A',97],[516,519,'A',101],
	[520,523,'A',105],[524,527,'A',111],[528,531,'A',114],[532,535,'A',117],[536,537,'A',115],[538,539,'A',116],[540,541],
	[542,543,'A',104],[544,414],[546,548,'R',1],[550,551,'A',97],[552,553,'A',101],[554,555,'A',246],[556,557,'A',245],
	[558,559,'A',111],[560,561,'A',559],[562,563,'A',121],[570,11365],[571,572],[573,410],[574,11366],[577,578],[579,384],
	[580,649],[581,652],[582,590,'R',1],[688,104],[689,614],[690,106],[691,114],[692,633],[693,635],[694,641],[695,119],
	[696,121],[728,733,'A',32],[736,611],[737,108],[738,115],[739,120],[740,661],[832,836,'R',0],[880,882,'R',1],[884,697],
	[886,887],[890,32],[894,59],[900,32],[901,168],[902,945],[903,183],[904,949],[905,951],[906,953],[908,959],[910,965],
	[911,912,'R',58],[913,937,'R',32],[938,953],[939,965],[940,945],[941,949],[942,951],[943,953],[944,971],[970,953],
	[971,965],[972,959],[973,965],[974,969],[975,983],[976,946],[977,952],[978,933],[979,980,'A',978],[981,966],[982,960],
	[984,1006,'R',1],[1008,954],[1009,1010,'R',-48],[1012,952],[1013,949],[1015,1016],[1017,962],[1018,1019],
	[1021,1023,'R',-130],[1024,1025,'A',1077],[1026,1106],[1027,1075],[1028,1030,'R',80],[1031,1110],[1032,1035,'R',80],
	[1036,1082],[1037,1080],[1038,1091],[1039,1119],[1040,1048,'R',32],[1049,1080],[1050,1071,'R',32],[1081,1080],
	[1104,1105,'A',1077],[1107,1075],[1111,1110],[1116,1082],[1117,1080],[1118,1091],[1120,1140,'R',1],[1142,1143,'A',1141],
	[1144,1214,'R',1],[1216,1231],[1217,1218,'A',1078],[1219,1229,'R',1],[1232,1235,'A',1072],[1236,1237],
	[1238,1239,'A',1077],[1240,1243,'A',1241],[1244,1245,'A',1078],[1246,1247,'A',1079],[1248,1249],[1250,1253,'A',1080],
	[1254,1255,'A',1086],[1256,1259,'A',1257],[1260,1261,'A',1101],[1262,1267,'A',1091],[1268,1269,'A',1095],[1270,1271],
	[1272,1273,'A',1099],[1274,1318,'R',1],[1329,1366,'R',48],[1415,[1381, 1410]],[1570,1571,'A',1575],[1572,1608],
	[1573,1575],[1574,1610],[1653,[1575, 1652]],[1654,[1608, 1652]],[1655,[1735, 1652]],[1656,[1610, 1652]],[1728,1749],
	[1730,2356,'R',-1],[2392,2394,'R',-67],[2395,2332],[2396,2397,'R',-59],[2398,2347],[2399,2351],[2507,2508,'R',0],
	[2524,2525,'R',-59],[2527,2479],[2611,2610],[2614,2616],[2649,2650,'R',-67],[2651,2588],[2654,2603],[2888,2892,'R',0],
	[2908,2909,'R',-59],[2964,2962],[3018,3550,'R',0],[3635,3763,'R',-1],[3804,[3755, 3737]],[3805,[3755, 3745]],
	[3852,3932,'R',-1],[3945,3904],[3955,4025,'R',0],[4134,4133],[4256,4301,'R',7264],[4348,4316],[6918,6930,'R',-1],
	[6971,6979,'R',0],[7468,65],[7469,198],[7470,7473,'R',-7404],[7474,398],[7475,7482,'R',-7404],[7484,79],[7485,546],
	[7486,80],[7487,82],[7488,7489,'R',-7404],[7490,87],[7491,97],[7492,7493,'R',-6900],[7494,7426],[7495,98],
	[7496,7497,'R',-7396],[7498,601],[7499,7500,'R',-6896],[7501,103],[7503,107],[7504,109],[7505,331],[7506,111],[7507,596],
	[7508,7509,'R',-62],[7510,112],[7511,7512,'R',-7395],[7513,7453],[7514,623],[7515,118],[7516,7461],[7517,7519,'R',-6571],
	[7520,7521,'R',-6554],[7522,105],[7523,114],[7524,7525,'R',-7407],[7526,7527,'R',-6580],[7528,961],[7529,7530,'R',-6563],
	[7544,1085],[7579,594],[7580,99],[7581,597],[7582,240],[7583,604],[7584,102],[7585,607],[7586,609],[7587,613],
	[7588,7590,'R',-6972],[7591,7547],[7592,669],[7593,621],[7594,7557],[7595,671],[7596,625],[7597,624],
	[7598,7601,'R',-6972],[7602,632],[7603,7604,'R',-6961],[7605,427],[7606,7607,'R',-6957],[7608,7452],
	[7609,7610,'R',-6958],[7611,122],[7612,7614,'R',-6956],[7615,952],[7680,7681,'A',97],[7682,7687,'A',98],
	[7688,7689,'A',231],[7690,7699,'A',100],[7700,7703,'A',275],[7704,7707,'A',101],[7708,7709,'A',553],[7710,7711,'A',102],
	[7712,7713,'A',103],[7714,7723,'A',104],[7724,7725,'A',105],[7726,7727,'A',239],[7728,7733,'A',107],[7734,7735,'A',108],
	[7736,7737,'A',7735],[7738,7741,'A',108],[7742,7747,'A',109],[7748,7755,'A',110],[7756,7759,'A',245],[7760,7763,'A',333],
	[7764,7767,'A',112],[7768,7771,'A',114],[7772,7773,'A',7771],[7774,7775,'A',114],[7776,7779,'A',115],[7780,7781,'A',347],
	[7782,7783,'A',353],[7784,7785,'A',7779],[7786,7793,'A',116],[7794,7799,'A',117],[7800,7801,'A',361],[7802,7803,'A',363],
	[7804,7807,'A',118],[7808,7817,'A',119],[7818,7821,'A',120],[7822,7823,'A',121],[7824,7829,'A',122],[7830,104],
	[7831,116],[7832,119],[7833,121],[7834,[97, 702]],[7835,383],[7838,223],[7840,7843,'A',97],[7844,7851,'A',226],
	[7852,7853,'A',7841],[7854,7861,'A',259],[7862,7863,'A',7841],[7864,7869,'A',101],[7870,7877,'A',234],
	[7878,7879,'A',7865],[7880,7883,'A',105],[7884,7887,'A',111],[7888,7895,'A',244],[7896,7897,'A',7885],
	[7898,7907,'A',417],[7908,7911,'A',117],[7912,7921,'A',432],[7922,7929,'A',121],[7930,7934,'R',1],[7936,7937,'A',945],
	[7938,7939,'R',-2],[7940,7941,'R',-4],[7942,7943,'R',-6],[7944,7945,'A',945],[7946,7947,'R',-10],[7948,7949,'R',-12],
	[7950,7951,'R',-14],[7952,7953,'A',949],[7954,7955,'R',-2],[7956,7957,'R',-4],[7960,7961,'A',949],[7962,7963,'R',-10],
	[7964,7965,'R',-12],[7968,7969,'A',951],[7970,7971,'R',-2],[7972,7973,'R',-4],[7974,7975,'R',-6],[7976,7977,'A',951],
	[7978,7979,'R',-10],[7980,7981,'R',-12],[7982,7983,'R',-14],[7984,7985,'A',953],[7986,7987,'R',-2],[7988,7989,'R',-4],
	[7990,7991,'R',-6],[7992,7993,'A',953],[7994,7995,'R',-10],[7996,7997,'R',-12],[7998,7999,'R',-14],[8000,8001,'A',959],
	[8002,8003,'R',-2],[8004,8005,'R',-4],[8008,8009,'A',959],[8010,8011,'R',-10],[8012,8013,'R',-12],[8016,8017,'A',965],
	[8018,8019,'R',-2],[8020,8021,'R',-4],[8022,8023,'R',-6],[8025,965],[8027,8031,'A',8017],[8032,8033,'A',969],
	[8034,8035,'R',-2],[8036,8037,'R',-4],[8038,8039,'R',-6],[8040,8041,'A',969],[8042,8043,'R',-10],[8044,8045,'R',-12],
	[8046,8047,'R',-14],[8048,945],[8049,940],[8050,949],[8051,941],[8052,951],[8053,942],[8054,953],[8055,943],[8056,959],
	[8057,972],[8058,965],[8059,973],[8060,969],[8061,974],[8064,8071,'R',-128],[8072,8079,'R',-136],[8080,8087,'R',-112],
	[8088,8095,'R',-120],[8096,8103,'R',-64],[8104,8111,'R',-72],[8112,8113,'A',945],[8114,8048],[8115,945],[8116,940],
	[8118,945],[8119,8118],[8120,8122,'A',945],[8123,940],[8124,945],[8125,32],[8126,953],[8127,8128,'A',32],[8129,168],
	[8130,8052],[8131,951],[8132,942],[8134,951],[8135,8134],[8136,949],[8137,941],[8138,951],[8139,942],[8140,951],
	[8141,8143,'A',8127],[8144,8145,'A',953],[8146,970],[8147,912],[8150,953],[8151,970],[8152,8154,'A',953],[8155,943],
	[8157,8159,'A',8190],[8160,8161,'A',965],[8162,971],[8163,944],[8164,8165,'A',961],[8166,965],[8167,971],
	[8168,8170,'A',965],[8171,973],[8172,961],[8173,168],[8174,901],[8175,96],[8178,8060],[8179,969],[8180,974],[8182,969],
	[8183,8182],[8184,959],[8185,972],[8186,969],[8187,974],[8188,969],[8189,180],[8190,32],[8192,8193,'R',2],
	[8194,8202,'A',32],[8209,8208],[8215,32],[8228,46],[8229,[46, 46]],[8230,[46, 46, 46]],[8239,32],[8243,[8242, 8242]],
	[8244,[8242, 8242, 8242]],[8246,[8245, 8245]],[8247,[8245, 8245, 8245]],[8252,[33, 33]],[8254,32],[8263,[63, 63]],
	[8264,[63, 33]],[8265,[33, 63]],[8279,[8242, 8242, 8242, 8242]],[8287,32],[8304,48],[8305,105],[8308,8313,'R',-8256],
	[8314,43],[8315,8722],[8316,61],[8317,8318,'R',-8277],[8319,110],[8320,8329,'R',-8272],[8330,43],[8331,8722],[8332,61],
	[8333,8334,'R',-8293],[8336,97],[8337,101],[8338,111],[8339,120],[8340,601],[8341,104],[8342,8345,'R',-8235],[8346,112],
	[8347,8348,'R',-8232],[8360,[82, 115]],[8448,[97, 47, 99]],[8449,[97, 47, 115]],[8450,67],[8451,[176, 67]],
	[8453,[99, 47, 111]],[8454,[99, 47, 117]],[8455,400],[8457,[176, 70]],[8458,103],[8459,8461,'A',72],[8462,104],
	[8463,295],[8464,8465,'A',73],[8466,76],[8467,108],[8469,78],[8470,[78, 111]],[8473,8475,'R',-8393],[8476,8477,'A',82],
	[8480,[83, 77]],[8481,[84, 69, 76]],[8482,[84, 77]],[8484,90],[8486,969],[8488,90],[8490,107],[8491,97],
	[8492,8493,'R',-8426],[8495,101],[8496,8497,'R',-8427],[8498,8526],[8499,77],[8500,111],[8501,8504,'R',-7013],[8505,105],
	[8507,[70, 65, 88]],[8508,960],[8509,947],[8510,915],[8511,928],[8512,8721],[8517,68],[8518,8519,'R',-8418],
	[8520,8521,'R',-8415],[8528,[49, 8260, 55]],[8529,[49, 8260, 57]],[8530,[49, 8260, 49, 48]],[8531,[49, 8260, 51]],
	[8532,[50, 8260, 51]],[8533,[49, 8260, 53]],[8534,[50, 8260, 53]],[8535,[51, 8260, 53]],[8536,[52, 8260, 53]],
	[8537,[49, 8260, 54]],[8538,[53, 8260, 54]],[8539,[49, 8260, 56]],[8540,[51, 8260, 56]],[8541,[53, 8260, 56]],
	[8542,[55, 8260, 56]],[8543,[49, 8260]],[8544,105],[8545,[105, 105]],[8546,[105, 105, 105]],[8547,[105, 118]],[8548,118],
	[8549,[118, 105]],[8550,[118, 105, 105]],[8551,[118, 105, 105, 105]],[8552,[105, 120]],[8553,120],[8554,[120, 105]],
	[8555,[120, 105, 105]],[8556,108],[8557,8558,'R',-8458],[8559,109],[8560,105],[8561,[105, 105]],[8562,[105, 105, 105]],
	[8563,[105, 118]],[8564,118],[8565,[118, 105]],[8566,[118, 105, 105]],[8567,[118, 105, 105, 105]],[8568,[105, 120]],
	[8569,120],[8570,[120, 105]],[8571,[120, 105, 105]],[8572,108],[8573,8574,'R',-8474],[8575,109],[8579,8580],
	[8585,[48, 8260, 51]],[8602,8592],[8603,8594],[8622,8596],[8653,8656],[8654,8660],[8655,8658],[8708,8742,'R',-1],
	[8748,[8747, 8747]],[8749,[8747, 8747, 8747]],[8751,[8750, 8750]],[8752,[8750, 8750, 8750]],[8769,8764],[8772,8771],
	[8775,8773],[8777,8776],[8800,61],[8802,8801],[8813,8781],[8814,60],[8815,62],[8816,8817,'R',-12],[8820,8825,'R',-2],
	[8832,8833,'R',-6],[8836,8841,'R',-2],[8876,8866],[8877,8878,'R',-5],[8879,8875],[8928,8929,'R',-100],
	[8930,8931,'R',-81],[8938,8941,'R',-56],[9001,9002,'R',3295],[9312,9320,'R',-9263],[9321,[49, 48]],[9322,[49, 49]],
	[9323,[49, 50]],[9324,[49, 51]],[9325,[49, 52]],[9326,[49, 53]],[9327,[49, 54]],[9328,[49, 55]],[9329,[49, 56]],
	[9330,[49, 57]],[9331,[50, 48]],[9332,[40, 49, 41]],[9333,[40, 50, 41]],[9334,[40, 51, 41]],[9335,[40, 52, 41]],
	[9336,[40, 53, 41]],[9337,[40, 54, 41]],[9338,[40, 55, 41]],[9339,[40, 56, 41]],[9340,[40, 57, 41]],
	[9341,[40, 49, 48, 41]],[9342,[40, 49, 49, 41]],[9343,[40, 49, 50, 41]],[9344,[40, 49, 51, 41]],[9345,[40, 49, 52, 41]],
	[9346,[40, 49, 53, 41]],[9347,[40, 49, 54, 41]],[9348,[40, 49, 55, 41]],[9349,[40, 49, 56, 41]],[9350,[40, 49, 57, 41]],
	[9351,[40, 50, 48, 41]],[9352,[49, 46]],[9353,[50, 46]],[9354,[51, 46]],[9355,[52, 46]],[9356,[53, 46]],[9357,[54, 46]],
	[9358,[55, 46]],[9359,[56, 46]],[9360,[57, 46]],[9361,[49, 48, 46]],[9362,[49, 49, 46]],[9363,[49, 50, 46]],
	[9364,[49, 51, 46]],[9365,[49, 52, 46]],[9366,[49, 53, 46]],[9367,[49, 54, 46]],[9368,[49, 55, 46]],[9369,[49, 56, 46]],
	[9370,[49, 57, 46]],[9371,[50, 48, 46]],[9372,[40, 97, 41]],[9373,[40, 98, 41]],[9374,[40, 99, 41]],[9375,[40, 100, 41]],
	[9376,[40, 101, 41]],[9377,[40, 102, 41]],[9378,[40, 103, 41]],[9379,[40, 104, 41]],[9380,[40, 105, 41]],
	[9381,[40, 106, 41]],[9382,[40, 107, 41]],[9383,[40, 108, 41]],[9384,[40, 109, 41]],[9385,[40, 110, 41]],
	[9386,[40, 111, 41]],[9387,[40, 112, 41]],[9388,[40, 113, 41]],[9389,[40, 114, 41]],[9390,[40, 115, 41]],
	[9391,[40, 116, 41]],[9392,[40, 117, 41]],[9393,[40, 118, 41]],[9394,[40, 119, 41]],[9395,[40, 120, 41]],
	[9396,[40, 121, 41]],[9397,[40, 122, 41]],[9398,9423,'R',-9301],[9424,9449,'R',-9327],[9450,48],
	[10764,[8747, 8747, 8747, 8747]],[10868,[58, 58, 61]],[10869,[61, 61]],[10870,[61, 61, 61]],[10972,10973],
	[11264,11310,'R',48],[11360,11361],[11362,619],[11363,7549],[11364,637],[11367,11371,'R',1],[11373,593],[11374,625],
	[11375,592],[11376,594],[11378,11381,'R',1],[11388,106],[11389,86],[11390,11391,'R',-10815],[11392,11506,'R',1],
	[11631,11617],[11935,12019,'R',0],[12032,19968],[12033,12245,'R',0],[12288,32],[12342,12306],[12344,12346,'R',0],
	[12364,12400,'R',-1],[12401,12399],[12403,12404,'A',12402],[12406,12407,'A',12405],[12409,12410,'A',12408],
	[12412,12413,'A',12411],[12436,12358],[12443,12444,'A',32],[12446,12445],[12447,[12424, 12426]],[12460,12496,'R',-1],
	[12497,12495],[12499,12500,'A',12498],[12502,12503,'A',12501],[12505,12506,'A',12504],[12508,12509,'A',12507],
	[12532,12454],[12535,12538,'R',-8],[12542,12541],[12543,[12467, 12488]],[12593,12594,'R',-8241],[12595,4522],
	[12596,4354],[12597,12598,'R',-8073],[12599,12601,'R',-8244],[12602,12607,'R',-8074],[12608,4378],
	[12609,12611,'R',-8251],[12612,4385],[12613,12622,'R',-8252],[12623,12643,'R',-8174],[12644,4448],
	[12645,12646,'R',-8273],[12647,12648,'R',-8096],[12649,4556],[12650,4558],[12651,4563],[12652,4567],[12653,4569],
	[12654,4380],[12655,4573],[12656,4575],[12657,12658,'R',-8276],[12659,4384],[12660,12661,'R',-8274],[12662,4391],
	[12663,4393],[12664,12668,'R',-8269],[12669,4402],[12670,4406],[12671,4416],[12672,4423],[12673,4428],
	[12674,12675,'R',-8081],[12676,12678,'R',-8237],[12679,12680,'R',-8195],[12681,4488],[12682,12683,'R',-8185],
	[12684,4500],[12685,4510],[12686,4513],[12690,19968],[12691,12703,'R',0],[12800,[40, 4352, 41]],[12801,[40, 4354, 41]],
	[12802,[40, 4355, 41]],[12803,[40, 4357, 41]],[12804,[40, 4358, 41]],[12805,[40, 4359, 41]],[12806,[40, 4361, 41]],
	[12807,[40, 4363, 41]],[12808,[40, 4364, 41]],[12809,[40, 4366, 41]],[12810,[40, 4367, 41]],[12811,[40, 4368, 41]],
	[12812,[40, 4369, 41]],[12813,[40, 4370, 41]],[12814,[40, 4352, 4449, 41]],[12815,[40, 4354, 4449, 41]],
	[12816,[40, 4355, 4449, 41]],[12817,[40, 4357, 4449, 41]],[12818,[40, 4358, 4449, 41]],[12819,[40, 4359, 4449, 41]],
	[12820,[40, 4361, 4449, 41]],[12821,[40, 4363, 4449, 41]],[12822,[40, 4364, 4449, 41]],[12823,[40, 4366, 4449, 41]],
	[12824,[40, 4367, 4449, 41]],[12825,[40, 4368, 4449, 41]],[12826,[40, 4369, 4449, 41]],[12827,[40, 4370, 4449, 41]],
	[12828,[40, 4364, 4462, 41]],[12829,[40, 4363, 4457, 4364, 4453, 4523, 41]],[12830,[40, 4363, 4457, 4370, 4462, 41]],
	[12832,[40, 19968, 41]],[12833,[40, 41]],[12834,[40, 41]],[12835,[40, 41]],[12836,[40, 41]],[12837,[40, 41]],
	[12838,[40, 41]],[12839,[40, 41]],[12840,[40, 41]],[12841,[40, 41]],[12842,[40, 41]],[12843,[40, 41]],[12844,[40, 41]],
	[12845,[40, 41]],[12846,[40, 41]],[12847,[40, 41]],[12848,[40, 41]],[12849,[40, 41]],[12850,[40, 41]],[12851,[40, 41]],
	[12852,[40, 41]],[12853,[40, 41]],[12854,[40, 41]],[12855,[40, 41]],[12856,[40, 41]],[12857,[40, 41]],[12858,[40, 41]],
	[12859,[40, 41]],[12860,[40, 41]],[12861,[40, 41]],[12862,[40, 41]],[12863,[40, 41]],[12864,[40, 41]],[12865,[40, 41]],
	[12866,[40, 41]],[12867,[40, 41]],[12868,12871,'R',0],[12880,[80, 84, 69]],[12881,[50, 49]],[12882,[50, 50]],
	[12883,[50, 51]],[12884,[50, 52]],[12885,[50, 53]],[12886,[50, 54]],[12887,[50, 55]],[12888,[50, 56]],[12889,[50, 57]],
	[12890,[51, 48]],[12891,[51, 49]],[12892,[51, 50]],[12893,[51, 51]],[12894,[51, 52]],[12895,[51, 53]],[12896,4352],
	[12897,12898,'R',-8543],[12899,12901,'R',-8542],[12902,4361],[12903,12904,'R',-8540],[12905,12909,'R',-8539],
	[12910,[4352, 4449]],[12911,[4354, 4449]],[12912,[4355, 4449]],[12913,[4357, 4449]],[12914,[4358, 4449]],
	[12915,[4359, 4449]],[12916,[4361, 4449]],[12917,[4363, 4449]],[12918,[4364, 4449]],[12919,[4366, 4449]],
	[12920,[4367, 4449]],[12921,[4368, 4449]],[12922,[4369, 4449]],[12923,[4370, 4449]],
	[12924,[4366, 4449, 4535, 4352, 4457]],[12925,[4364, 4462, 4363, 4468]],[12926,[4363, 4462]],[12928,19968],
	[12929,12976,'R',0],[12977,[51, 54]],[12978,[51, 55]],[12979,[51, 56]],[12980,[51, 57]],[12981,[52, 48]],
	[12982,[52, 49]],[12983,[52, 50]],[12984,[52, 51]],[12985,[52, 52]],[12986,[52, 53]],[12987,[52, 54]],[12988,[52, 55]],
	[12989,[52, 56]],[12990,[52, 57]],[12991,[53, 48]],[12992,13000,'R',-12943],[13001,[49, 48]],[13002,[49, 49]],
	[13003,[49, 50]],[13004,[72, 103]],[13005,[101, 114, 103]],[13006,[101, 86]],[13007,[76, 84, 68]],[13008,12450],
	[13009,12452],[13010,12454],[13011,12456],[13012,13013,'R',-554],[13014,12461],[13015,12463],[13016,12465],[13017,12467],
	[13018,12469],[13019,12471],[13020,12473],[13021,12475],[13022,12477],[13023,12479],[13024,12481],[13025,12484],
	[13026,12486],[13027,12488],[13028,13033,'R',-538],[13034,12498],[13035,12501],[13036,12504],[13037,12507],
	[13038,13042,'R',-528],[13043,12516],[13044,12518],[13045,13050,'R',-525],[13051,13054,'R',-524],
	[13056,[12450, 12497, 12540, 12488]],[13057,[12450, 12523, 12501, 12449]],[13058,[12450, 12531, 12506, 12450]],
	[13059,[12450, 12540, 12523]],[13060,[12452, 12491, 12531, 12464]],[13061,[12452, 12531, 12481]],
	[13062,[12454, 12457, 12531]],[13063,[12456, 12473, 12463, 12540, 12489]],[13064,[12456, 12540, 12459, 12540]],
	[13065,[12458, 12531, 12473]],[13066,[12458, 12540, 12512]],[13067,[12459, 12452, 12522]],
	[13068,[12459, 12521, 12483, 12488]],[13069,[12459, 12525, 12522, 12540]],[13070,[12460, 12525, 12531]],
	[13071,[12460, 12531, 12510]],[13072,[12462, 12460]],[13073,[12462, 12491, 12540]],[13074,[12461, 12517, 12522, 12540]],
	[13075,[12462, 12523, 12480, 12540]],[13076,[12461, 12525]],[13077,[12461, 12525, 12464, 12521, 12512]],
	[13078,[12461, 12525, 12513, 12540, 12488, 12523]],[13079,[12461, 12525, 12527, 12483, 12488]],
	[13080,[12464, 12521, 12512]],[13081,[12464, 12521, 12512, 12488, 12531]],[13082,[12463, 12523, 12476, 12452, 12525]],
	[13083,[12463, 12525, 12540, 12493]],[13084,[12465, 12540, 12473]],[13085,[12467, 12523, 12490]],
	[13086,[12467, 12540, 12509]],[13087,[12469, 12452, 12463, 12523]],[13088,[12469, 12531, 12481, 12540, 12512]],
	[13089,[12471, 12522, 12531, 12464]],[13090,[12475, 12531, 12481]],[13091,[12475, 12531, 12488]],
	[13092,[12480, 12540, 12473]],[13093,[12487, 12471]],[13094,[12489, 12523]],[13095,[12488, 12531]],
	[13096,[12490, 12494]],[13097,[12494, 12483, 12488]],[13098,[12495, 12452, 12484]],
	[13099,[12497, 12540, 12475, 12531, 12488]],[13100,[12497, 12540, 12484]],[13101,[12496, 12540, 12524, 12523]],
	[13102,[12500, 12450, 12473, 12488, 12523]],[13103,[12500, 12463, 12523]],[13104,[12500, 12467]],[13105,[12499, 12523]],
	[13106,[12501, 12449, 12521, 12483, 12489]],[13107,[12501, 12451, 12540, 12488]],
	[13108,[12502, 12483, 12471, 12455, 12523]],[13109,[12501, 12521, 12531]],[13110,[12504, 12463, 12479, 12540, 12523]],
	[13111,[12506, 12477]],[13112,[12506, 12491, 12498]],[13113,[12504, 12523, 12484]],[13114,[12506, 12531, 12473]],
	[13115,[12506, 12540, 12472]],[13116,[12505, 12540, 12479]],[13117,[12509, 12452, 12531, 12488]],
	[13118,[12508, 12523, 12488]],[13119,[12507, 12531]],[13120,[12509, 12531, 12489]],[13121,[12507, 12540, 12523]],
	[13122,[12507, 12540, 12531]],[13123,[12510, 12452, 12463, 12525]],[13124,[12510, 12452, 12523]],
	[13125,[12510, 12483, 12495]],[13126,[12510, 12523, 12463]],[13127,[12510, 12531, 12471, 12519, 12531]],
	[13128,[12511, 12463, 12525, 12531]],[13129,[12511, 12522]],[13130,[12511, 12522, 12496, 12540, 12523]],
	[13131,[12513, 12460]],[13132,[12513, 12460, 12488, 12531]],[13133,[12513, 12540, 12488, 12523]],
	[13134,[12516, 12540, 12489]],[13135,[12516, 12540, 12523]],[13136,[12518, 12450, 12531]],
	[13137,[12522, 12483, 12488, 12523]],[13138,[12522, 12521]],[13139,[12523, 12500, 12540]],
	[13140,[12523, 12540, 12502, 12523]],[13141,[12524, 12512]],[13142,[12524, 12531, 12488, 12466, 12531]],
	[13143,[12527, 12483, 12488]],[13144,13153,'R',-13096],[13154,[49, 48]],[13155,[49, 49]],[13156,[49, 50]],
	[13157,[49, 51]],[13158,[49, 52]],[13159,[49, 53]],[13160,[49, 54]],[13161,[49, 55]],[13162,[49, 56]],[13163,[49, 57]],
	[13164,[50, 48]],[13165,[50, 49]],[13166,[50, 50]],[13167,[50, 51]],[13168,[50, 52]],[13169,[104, 80, 97]],
	[13170,[100, 97]],[13171,[65, 85]],[13172,[98, 97, 114]],[13173,[111, 86]],[13174,[112, 99]],[13175,[100, 109]],
	[13176,[100, 109, 178]],[13177,[100, 109, 179]],[13178,[73, 85]],[13179,13183,'R',0],[13184,[112, 65]],[13185,[110, 65]],
	[13186,[956, 65]],[13187,[109, 65]],[13188,[107, 65]],[13189,[75, 66]],[13190,[77, 66]],[13191,[71, 66]],
	[13192,[99, 97, 108]],[13193,[107, 99, 97, 108]],[13194,[112, 70]],[13195,[110, 70]],[13196,[956, 70]],
	[13197,[956, 103]],[13198,[109, 103]],[13199,[107, 103]],[13200,[72, 122]],[13201,[107, 72, 122]],[13202,[77, 72, 122]],
	[13203,[71, 72, 122]],[13204,[84, 72, 122]],[13205,[956, 8467]],[13206,[109, 8467]],[13207,[100, 8467]],
	[13208,[107, 8467]],[13209,[102, 109]],[13210,[110, 109]],[13211,[956, 109]],[13212,[109, 109]],[13213,[99, 109]],
	[13214,[107, 109]],[13215,[109, 109, 178]],[13216,[99, 109, 178]],[13217,[109, 178]],[13218,[107, 109, 178]],
	[13219,[109, 109, 179]],[13220,[99, 109, 179]],[13221,[109, 179]],[13222,[107, 109, 179]],[13223,[109, 8725, 115]],
	[13224,[109, 8725, 115, 178]],[13225,[80, 97]],[13226,[107, 80, 97]],[13227,[77, 80, 97]],[13228,[71, 80, 97]],
	[13229,[114, 97, 100]],[13230,[114, 97, 100, 8725, 115]],[13231,[114, 97, 100, 8725, 115, 178]],[13232,[112, 115]],
	[13233,[110, 115]],[13234,[956, 115]],[13235,[109, 115]],[13236,[112, 86]],[13237,[110, 86]],[13238,[956, 86]],
	[13239,[109, 86]],[13240,[107, 86]],[13241,[77, 86]],[13242,[112, 87]],[13243,[110, 87]],[13244,[956, 87]],
	[13245,[109, 87]],[13246,[107, 87]],[13247,[77, 87]],[13248,[107, 937]],[13249,[77, 937]],[13250,[97, 46, 109, 46]],
	[13251,[66, 113]],[13252,[99, 99]],[13253,[99, 100]],[13254,[67, 8725, 107, 103]],[13255,[67, 111, 46]],
	[13256,[100, 66]],[13257,[71, 121]],[13258,[104, 97]],[13259,[72, 80]],[13260,[105, 110]],[13261,[75, 75]],
	[13262,[75, 77]],[13263,[107, 116]],[13264,[108, 109]],[13265,[108, 110]],[13266,[108, 111, 103]],[13267,[108, 120]],
	[13268,[109, 98]],[13269,[109, 105, 108]],[13270,[109, 111, 108]],[13271,[80, 72]],[13272,[112, 46, 109, 46]],
	[13273,[80, 80, 77]],[13274,[80, 82]],[13275,[115, 114]],[13276,[83, 118]],[13277,[87, 98]],[13278,[86, 8725, 109]],
	[13279,[65, 8725, 109]],[13280,13288,'R',-13231],[13289,[49, 48]],[13290,[49, 49]],[13291,[49, 50]],[13292,[49, 51]],
	[13293,[49, 52]],[13294,[49, 53]],[13295,[49, 54]],[13296,[49, 55]],[13297,[49, 56]],[13298,[49, 57]],[13299,[50, 48]],
	[13300,[50, 49]],[13301,[50, 50]],[13302,[50, 51]],[13303,[50, 52]],[13304,[50, 53]],[13305,[50, 54]],[13306,[50, 55]],
	[13307,[50, 56]],[13308,[50, 57]],[13309,[51, 48]],[13310,[51, 49]],[13311,[103, 97, 108]],[42560,42862,'R',1],
	[42864,42863],[42873,42875,'R',1],[42877,7545],[42878,42891,'R',1],[42893,613],[42896,42920,'R',1],[42922,614],
	[43000,294],[43001,339],[63744,64217,'R',0],[64256,[102, 102]],[64257,[102, 105]],[64258,[102, 108]],
	[64259,[102, 102, 105]],[64260,[102, 102, 108]],[64261,[383, 116]],[64262,[115, 116]],[64275,[1396, 1398]],
	[64276,[1396, 1381]],[64277,[1396, 1387]],[64278,[1406, 1398]],[64279,[1396, 1389]],[64285,1497],[64287,1522],
	[64288,1506],[64289,1488],[64290,64291,'R',-62799],[64292,64294,'R',-62793],[64295,1512],[64296,1514],[64297,43],
	[64298,64299,'A',1513],[64300,64301,'A',64329],[64302,64304,'A',1488],[64305,64330,'R',-62816],[64331,1493],[64332,1489],
	[64333,1499],[64334,1508],[64335,[1488, 1500]],[64336,64337,'A',1649],[64338,64341,'A',1659],[64342,64345,'A',1662],
	[64346,64349,'A',1664],[64350,64353,'A',1658],[64354,64357,'A',1663],[64358,64361,'A',1657],[64362,64365,'A',1700],
	[64366,64369,'A',1702],[64370,64373,'A',1668],[64374,64377,'A',1667],[64378,64381,'A',1670],[64382,64385,'A',1671],
	[64386,64387,'A',1677],[64388,64389,'A',1676],[64390,64391,'A',1678],[64392,64393,'A',1672],[64394,64395,'A',1688],
	[64396,64397,'A',1681],[64398,64401,'A',1705],[64402,64405,'A',1711],[64406,64409,'A',1715],[64410,64413,'A',1713],
	[64414,64415,'A',1722],[64416,64419,'A',1723],[64420,64421,'A',1728],[64422,64425,'A',1729],[64426,64429,'A',1726],
	[64430,64431,'A',1746],[64432,64433,'A',1747],[64467,64470,'A',1709],[64471,64472,'A',1735],[64473,64474,'A',1734],
	[64475,64476,'A',1736],[64477,1655],[64478,64479,'A',1739],[64480,64481,'A',1733],[64482,64483,'A',1737],
	[64484,64487,'A',1744],[64488,64489,'A',1609],[64490,[1574, 1575]],[64491,[1574, 1575]],[64492,[1574, 1749]],
	[64493,[1574, 1749]],[64494,[1574, 1608]],[64495,[1574, 1608]],[64496,[1574, 1735]],[64497,[1574, 1735]],
	[64498,[1574, 1734]],[64499,[1574, 1734]],[64500,[1574, 1736]],[64501,[1574, 1736]],[64502,[1574, 1744]],
	[64503,[1574, 1744]],[64504,[1574, 1744]],[64505,[1574, 1609]],[64506,[1574, 1609]],[64507,[1574, 1609]],
	[64508,64511,'A',1740],[64512,[1574, 1580]],[64513,[1574, 1581]],[64514,[1574, 1605]],[64515,[1574, 1609]],
	[64516,[1574, 1610]],[64517,[1576, 1580]],[64518,[1576, 1581]],[64519,[1576, 1582]],[64520,[1576, 1605]],
	[64521,[1576, 1609]],[64522,[1576, 1610]],[64523,[1578, 1580]],[64524,[1578, 1581]],[64525,[1578, 1582]],
	[64526,[1578, 1605]],[64527,[1578, 1609]],[64528,[1578, 1610]],[64529,[1579, 1580]],[64530,[1579, 1605]],
	[64531,[1579, 1609]],[64532,[1579, 1610]],[64533,[1580, 1581]],[64534,[1580, 1605]],[64535,[1581, 1580]],
	[64536,[1581, 1605]],[64537,[1582, 1580]],[64538,[1582, 1581]],[64539,[1582, 1605]],[64540,[1587, 1580]],
	[64541,[1587, 1581]],[64542,[1587, 1582]],[64543,[1587, 1605]],[64544,[1589, 1581]],[64545,[1589, 1605]],
	[64546,[1590, 1580]],[64547,[1590, 1581]],[64548,[1590, 1582]],[64549,[1590, 1605]],[64550,[1591, 1581]],
	[64551,[1591, 1605]],[64552,[1592, 1605]],[64553,[1593, 1580]],[64554,[1593, 1605]],[64555,[1594, 1580]],
	[64556,[1594, 1605]],[64557,[1601, 1580]],[64558,[1601, 1581]],[64559,[1601, 1582]],[64560,[1601, 1605]],
	[64561,[1601, 1609]],[64562,[1601, 1610]],[64563,[1602, 1581]],[64564,[1602, 1605]],[64565,[1602, 1609]],
	[64566,[1602, 1610]],[64567,[1603, 1575]],[64568,[1603, 1580]],[64569,[1603, 1581]],[64570,[1603, 1582]],
	[64571,[1603, 1604]],[64572,[1603, 1605]],[64573,[1603, 1609]],[64574,[1603, 1610]],[64575,[1604, 1580]],
	[64576,[1604, 1581]],[64577,[1604, 1582]],[64578,[1604, 1605]],[64579,[1604, 1609]],[64580,[1604, 1610]],
	[64581,[1605, 1580]],[64582,[1605, 1581]],[64583,[1605, 1582]],[64584,[1605, 1605]],[64585,[1605, 1609]],
	[64586,[1605, 1610]],[64587,[1606, 1580]],[64588,[1606, 1581]],[64589,[1606, 1582]],[64590,[1606, 1605]],
	[64591,[1606, 1609]],[64592,[1606, 1610]],[64593,[1607, 1580]],[64594,[1607, 1605]],[64595,[1607, 1609]],
	[64596,[1607, 1610]],[64597,[1610, 1580]],[64598,[1610, 1581]],[64599,[1610, 1582]],[64600,[1610, 1605]],
	[64601,[1610, 1609]],[64602,[1610, 1610]],[64603,64604,'R',-63019],[64605,1609],[64606,64611,'A',32],
	[64612,[1574, 1585]],[64613,[1574, 1586]],[64614,[1574, 1605]],[64615,[1574, 1606]],[64616,[1574, 1609]],
	[64617,[1574, 1610]],[64618,[1576, 1585]],[64619,[1576, 1586]],[64620,[1576, 1605]],[64621,[1576, 1606]],
	[64622,[1576, 1609]],[64623,[1576, 1610]],[64624,[1578, 1585]],[64625,[1578, 1586]],[64626,[1578, 1605]],
	[64627,[1578, 1606]],[64628,[1578, 1609]],[64629,[1578, 1610]],[64630,[1579, 1585]],[64631,[1579, 1586]],
	[64632,[1579, 1605]],[64633,[1579, 1606]],[64634,[1579, 1609]],[64635,[1579, 1610]],[64636,[1601, 1609]],
	[64637,[1601, 1610]],[64638,[1602, 1609]],[64639,[1602, 1610]],[64640,[1603, 1575]],[64641,[1603, 1604]],
	[64642,[1603, 1605]],[64643,[1603, 1609]],[64644,[1603, 1610]],[64645,[1604, 1605]],[64646,[1604, 1609]],
	[64647,[1604, 1610]],[64648,[1605, 1575]],[64649,[1605, 1605]],[64650,[1606, 1585]],[64651,[1606, 1586]],
	[64652,[1606, 1605]],[64653,[1606, 1606]],[64654,[1606, 1609]],[64655,[1606, 1610]],[64656,1609],[64657,[1610, 1585]],
	[64658,[1610, 1586]],[64659,[1610, 1605]],[64660,[1610, 1606]],[64661,[1610, 1609]],[64662,[1610, 1610]],
	[64663,[1574, 1580]],[64664,[1574, 1581]],[64665,[1574, 1582]],[64666,[1574, 1605]],[64667,[1574, 1607]],
	[64668,[1576, 1580]],[64669,[1576, 1581]],[64670,[1576, 1582]],[64671,[1576, 1605]],[64672,[1576, 1607]],
	[64673,[1578, 1580]],[64674,[1578, 1581]],[64675,[1578, 1582]],[64676,[1578, 1605]],[64677,[1578, 1607]],
	[64678,[1579, 1605]],[64679,[1580, 1581]],[64680,[1580, 1605]],[64681,[1581, 1580]],[64682,[1581, 1605]],
	[64683,[1582, 1580]],[64684,[1582, 1605]],[64685,[1587, 1580]],[64686,[1587, 1581]],[64687,[1587, 1582]],
	[64688,[1587, 1605]],[64689,[1589, 1581]],[64690,[1589, 1582]],[64691,[1589, 1605]],[64692,[1590, 1580]],
	[64693,[1590, 1581]],[64694,[1590, 1582]],[64695,[1590, 1605]],[64696,[1591, 1581]],[64697,[1592, 1605]],
	[64698,[1593, 1580]],[64699,[1593, 1605]],[64700,[1594, 1580]],[64701,[1594, 1605]],[64702,[1601, 1580]],
	[64703,[1601, 1581]],[64704,[1601, 1582]],[64705,[1601, 1605]],[64706,[1602, 1581]],[64707,[1602, 1605]],
	[64708,[1603, 1580]],[64709,[1603, 1581]],[64710,[1603, 1582]],[64711,[1603, 1604]],[64712,[1603, 1605]],
	[64713,[1604, 1580]],[64714,[1604, 1581]],[64715,[1604, 1582]],[64716,[1604, 1605]],[64717,[1604, 1607]],
	[64718,[1605, 1580]],[64719,[1605, 1581]],[64720,[1605, 1582]],[64721,[1605, 1605]],[64722,[1606, 1580]],
	[64723,[1606, 1581]],[64724,[1606, 1582]],[64725,[1606, 1605]],[64726,[1606, 1607]],[64727,[1607, 1580]],
	[64728,[1607, 1605]],[64729,1607],[64730,[1610, 1580]],[64731,[1610, 1581]],[64732,[1610, 1582]],[64733,[1610, 1605]],
	[64734,[1610, 1607]],[64735,[1574, 1605]],[64736,[1574, 1607]],[64737,[1576, 1605]],[64738,[1576, 1607]],
	[64739,[1578, 1605]],[64740,[1578, 1607]],[64741,[1579, 1605]],[64742,[1579, 1607]],[64743,[1587, 1605]],
	[64744,[1587, 1607]],[64745,[1588, 1605]],[64746,[1588, 1607]],[64747,[1603, 1604]],[64748,[1603, 1605]],
	[64749,[1604, 1605]],[64750,[1606, 1605]],[64751,[1606, 1607]],[64752,[1610, 1605]],[64753,[1610, 1607]],
	[64754,64756,'A',1600],[64757,[1591, 1609]],[64758,[1591, 1610]],[64759,[1593, 1609]],[64760,[1593, 1610]],
	[64761,[1594, 1609]],[64762,[1594, 1610]],[64763,[1587, 1609]],[64764,[1587, 1610]],[64765,[1588, 1609]],
	[64766,[1588, 1610]],[64767,[1581, 1609]],[64768,[1581, 1610]],[64769,[1580, 1609]],[64770,[1580, 1610]],
	[64771,[1582, 1609]],[64772,[1582, 1610]],[64773,[1589, 1609]],[64774,[1589, 1610]],[64775,[1590, 1609]],
	[64776,[1590, 1610]],[64777,[1588, 1580]],[64778,[1588, 1581]],[64779,[1588, 1582]],[64780,[1588, 1605]],
	[64781,[1588, 1585]],[64782,[1587, 1585]],[64783,[1589, 1585]],[64784,[1590, 1585]],[64785,[1591, 1609]],
	[64786,[1591, 1610]],[64787,[1593, 1609]],[64788,[1593, 1610]],[64789,[1594, 1609]],[64790,[1594, 1610]],
	[64791,[1587, 1609]],[64792,[1587, 1610]],[64793,[1588, 1609]],[64794,[1588, 1610]],[64795,[1581, 1609]],
	[64796,[1581, 1610]],[64797,[1580, 1609]],[64798,[1580, 1610]],[64799,[1582, 1609]],[64800,[1582, 1610]],
	[64801,[1589, 1609]],[64802,[1589, 1610]],[64803,[1590, 1609]],[64804,[1590, 1610]],[64805,[1588, 1580]],
	[64806,[1588, 1581]],[64807,[1588, 1582]],[64808,[1588, 1605]],[64809,[1588, 1585]],[64810,[1587, 1585]],
	[64811,[1589, 1585]],[64812,[1590, 1585]],[64813,[1588, 1580]],[64814,[1588, 1581]],[64815,[1588, 1582]],
	[64816,[1588, 1605]],[64817,[1587, 1607]],[64818,[1588, 1607]],[64819,[1591, 1605]],[64820,[1587, 1580]],
	[64821,[1587, 1581]],[64822,[1587, 1582]],[64823,[1588, 1580]],[64824,[1588, 1581]],[64825,[1588, 1582]],
	[64826,[1591, 1605]],[64827,[1592, 1605]],[64828,64829,'A',1575],[64848,[1578, 1580, 1605]],[64849,[1578, 1581, 1580]],
	[64850,[1578, 1581, 1580]],[64851,[1578, 1581, 1605]],[64852,[1578, 1582, 1605]],[64853,[1578, 1605, 1580]],
	[64854,[1578, 1605, 1581]],[64855,[1578, 1605, 1582]],[64856,[1580, 1605, 1581]],[64857,[1580, 1605, 1581]],
	[64858,[1581, 1605, 1610]],[64859,[1581, 1605, 1609]],[64860,[1587, 1581, 1580]],[64861,[1587, 1580, 1581]],
	[64862,[1587, 1580, 1609]],[64863,[1587, 1605, 1581]],[64864,[1587, 1605, 1581]],[64865,[1587, 1605, 1580]],
	[64866,[1587, 1605, 1605]],[64867,[1587, 1605, 1605]],[64868,[1589, 1581, 1581]],[64869,[1589, 1581, 1581]],
	[64870,[1589, 1605, 1605]],[64871,[1588, 1581, 1605]],[64872,[1588, 1581, 1605]],[64873,[1588, 1580, 1610]],
	[64874,[1588, 1605, 1582]],[64875,[1588, 1605, 1582]],[64876,[1588, 1605, 1605]],[64877,[1588, 1605, 1605]],
	[64878,[1590, 1581, 1609]],[64879,[1590, 1582, 1605]],[64880,[1590, 1582, 1605]],[64881,[1591, 1605, 1581]],
	[64882,[1591, 1605, 1581]],[64883,[1591, 1605, 1605]],[64884,[1591, 1605, 1610]],[64885,[1593, 1580, 1605]],
	[64886,[1593, 1605, 1605]],[64887,[1593, 1605, 1605]],[64888,[1593, 1605, 1609]],[64889,[1594, 1605, 1605]],
	[64890,[1594, 1605, 1610]],[64891,[1594, 1605, 1609]],[64892,[1601, 1582, 1605]],[64893,[1601, 1582, 1605]],
	[64894,[1602, 1605, 1581]],[64895,[1602, 1605, 1605]],[64896,[1604, 1581, 1605]],[64897,[1604, 1581, 1610]],
	[64898,[1604, 1581, 1609]],[64899,[1604, 1580, 1580]],[64900,[1604, 1580, 1580]],[64901,[1604, 1582, 1605]],
	[64902,[1604, 1582, 1605]],[64903,[1604, 1605, 1581]],[64904,[1604, 1605, 1581]],[64905,[1605, 1581, 1580]],
	[64906,[1605, 1581, 1605]],[64907,[1605, 1581, 1610]],[64908,[1605, 1580, 1581]],[64909,[1605, 1580, 1605]],
	[64910,[1605, 1582, 1580]],[64911,[1605, 1582, 1605]],[64914,[1605, 1580, 1582]],[64915,[1607, 1605, 1580]],
	[64916,[1607, 1605, 1605]],[64917,[1606, 1581, 1605]],[64918,[1606, 1581, 1609]],[64919,[1606, 1580, 1605]],
	[64920,[1606, 1580, 1605]],[64921,[1606, 1580, 1609]],[64922,[1606, 1605, 1610]],[64923,[1606, 1605, 1609]],
	[64924,[1610, 1605, 1605]],[64925,[1610, 1605, 1605]],[64926,[1576, 1582, 1610]],[64927,[1578, 1580, 1610]],
	[64928,[1578, 1580, 1609]],[64929,[1578, 1582, 1610]],[64930,[1578, 1582, 1609]],[64931,[1578, 1605, 1610]],
	[64932,[1578, 1605, 1609]],[64933,[1580, 1605, 1610]],[64934,[1580, 1581, 1609]],[64935,[1580, 1605, 1609]],
	[64936,[1587, 1582, 1609]],[64937,[1589, 1581, 1610]],[64938,[1588, 1581, 1610]],[64939,[1590, 1581, 1610]],
	[64940,[1604, 1580, 1610]],[64941,[1604, 1605, 1610]],[64942,[1610, 1581, 1610]],[64943,[1610, 1580, 1610]],
	[64944,[1610, 1605, 1610]],[64945,[1605, 1605, 1610]],[64946,[1602, 1605, 1610]],[64947,[1606, 1581, 1610]],
	[64948,[1602, 1605, 1581]],[64949,[1604, 1581, 1605]],[64950,[1593, 1605, 1610]],[64951,[1603, 1605, 1610]],
	[64952,[1606, 1580, 1581]],[64953,[1605, 1582, 1610]],[64954,[1604, 1580, 1605]],[64955,[1603, 1605, 1605]],
	[64956,[1604, 1580, 1605]],[64957,[1606, 1580, 1581]],[64958,[1580, 1581, 1610]],[64959,[1581, 1580, 1610]],
	[64960,[1605, 1580, 1610]],[64961,[1601, 1605, 1610]],[64962,[1576, 1581, 1610]],[64963,[1603, 1605, 1605]],
	[64964,[1593, 1580, 1605]],[64965,[1589, 1605, 1605]],[64966,[1587, 1582, 1610]],[64967,[1606, 1580, 1610]],
	[65008,[1589, 1604, 1746]],[65009,[1602, 1604, 1746]],[65010,[1575, 1604, 1604, 1607]],[65011,[1575, 1603, 1576, 1585]],
	[65012,[1605, 1581, 1605, 1583]],[65013,[1589, 1604, 1593, 1605]],[65014,[1585, 1587, 1608, 1604]],
	[65015,[1593, 1604, 1610, 1607]],[65016,[1608, 1587, 1604, 1605]],[65017,[1589, 1604, 1609]],
	[65018,[1589, 1604, 1609, 32, 1575, 1604, 1604, 1607, 32, 1593, 1604, 1610, 1607, 32, 1608, 1587, 1604, 1605]],
	[65019,[1580, 1604, 32, 1580, 1604, 1575, 1604, 1607]],[65020,[1585, 1740, 1575, 1604]],[65040,44],
	[65041,65042,'R',-52752],[65043,65044,'R',-64985],[65045,33],[65046,63],[65047,65048,'R',-52737],[65049,8230],
	[65072,8229],[65073,8212],[65074,8211],[65075,65076,'A',95],[65077,65078,'R',-65037],[65079,123],[65080,125],
	[65081,65082,'R',-52773],[65083,65084,'R',-52779],[65085,65086,'R',-52787],[65087,65088,'R',-52791],
	[65089,65092,'R',-52789],[65095,91],[65096,93],[65097,65100,'A',8254],[65101,65103,'A',95],[65104,44],[65105,12289],
	[65106,46],[65108,59],[65109,58],[65110,63],[65111,33],[65112,8212],[65113,65114,'R',-65073],[65115,123],[65116,125],
	[65117,65118,'R',-52809],[65119,35],[65120,38],[65121,65122,'R',-65079],[65123,45],[65124,60],[65125,62],[65126,61],
	[65128,92],[65129,65130,'R',-65093],[65131,64],[65136,32],[65137,1600],[65138,65142,'A',32],[65143,1600],[65144,32],
	[65145,1600],[65146,32],[65147,1600],[65148,32],[65149,1600],[65150,32],[65151,1600],[65152,65153,'R',-63583],
	[65154,65155,'R',-63584],[65156,65157,'R',-63585],[65158,65159,'R',-63586],[65160,65161,'R',-63587],
	[65162,65164,'A',1574],[65165,65166,'A',1575],[65167,65170,'A',1576],[65171,65172,'A',1577],[65173,65176,'A',1578],
	[65177,65180,'A',1579],[65181,65184,'A',1580],[65185,65188,'A',1581],[65189,65192,'A',1582],[65193,65194,'A',1583],
	[65195,65196,'A',1584],[65197,65198,'A',1585],[65199,65200,'A',1586],[65201,65204,'A',1587],[65205,65208,'A',1588],
	[65209,65212,'A',1589],[65213,65216,'A',1590],[65217,65220,'A',1591],[65221,65224,'A',1592],[65225,65228,'A',1593],
	[65229,65232,'A',1594],[65233,65236,'A',1601],[65237,65240,'A',1602],[65241,65244,'A',1603],[65245,65248,'A',1604],
	[65249,65252,'A',1605],[65253,65256,'A',1606],[65257,65260,'A',1607],[65261,65262,'A',1608],[65263,65264,'A',1609],
	[65265,65268,'A',1610],[65269,[1604, 1570]],[65270,[1604, 1570]],[65271,[1604, 1571]],[65272,[1604, 1571]],
	[65273,[1604, 1573]],[65274,[1604, 1573]],[65275,[1604, 1575]],[65276,[1604, 1575]],[65281,65312,'R',-65248],
	[65313,65338,'R',-65216],[65339,65374,'R',-65248],[65375,65376,'R',-54746],[65377,12290],[65378,65379,'R',-53078],
	[65380,12289],[65381,12539],[65382,12530],[65383,12449],[65384,12451],[65385,12453],[65386,12455],[65387,12457],
	[65388,12515],[65389,12517],[65390,12519],[65391,12483],[65392,12540],[65393,12450],[65394,12452],[65395,12454],
	[65396,12456],[65397,65398,'R',-52939],[65399,12461],[65400,12463],[65401,12465],[65402,12467],[65403,12469],
	[65404,12471],[65405,12473],[65406,12475],[65407,12477],[65408,12479],[65409,12481],[65410,12484],[65411,12486],
	[65412,12488],[65413,65418,'R',-52923],[65419,12498],[65420,12501],[65421,12504],[65422,12507],[65423,65427,'R',-52913],
	[65428,12516],[65429,12518],[65430,65435,'R',-52910],[65436,12527],[65437,12531],[65438,65439,'R',0],[65440,12644],
	[65441,65470,'R',-52848],[65474,65479,'R',-52851],[65482,65487,'R',-52853],[65490,65495,'R',-52855],
	[65498,65500,'R',-52857],[65504,65505,'R',-65342],[65506,172],[65507,175],[65508,166],[65509,165],[65510,8361],
	[65512,9474],[65513,65516,'R',-56921],[65517,9632],[65518,9675],[66560,66599,'R',40],[69786,69788,'R',-1],[69803,69797],
	[69934,69935,'R',0],[119134,119135,'R',-7],[119136,119140,'A',119135],[119227,119230,'R',-2],[119231,119232,'R',-4],
	[119808,119833,'R',-119743],[119834,119859,'R',-119737],[119860,119885,'R',-119795],[119886,119911,'R',-119789],
	[119912,119937,'R',-119847],[119938,119963,'R',-119841],[119964,119989,'R',-119899],[119990,120015,'R',-119893],
	[120016,120041,'R',-119951],[120042,120067,'R',-119945],[120068,120092,'R',-120003],[120094,120119,'R',-119997],
	[120120,120144,'R',-120055],[120146,120171,'R',-120049],[120172,120197,'R',-120107],[120198,120223,'R',-120101],
	[120224,120249,'R',-120159],[120250,120275,'R',-120153],[120276,120301,'R',-120211],[120302,120327,'R',-120205],
	[120328,120353,'R',-120263],[120354,120379,'R',-120257],[120380,120405,'R',-120315],[120406,120431,'R',-120309],
	[120432,120457,'R',-120367],[120458,120483,'R',-120361],[120484,305],[120485,567],[120488,120504,'R',-119575],
	[120505,1012],[120506,120512,'R',-119575],[120513,8711],[120514,120538,'R',-119569],[120539,8706],[120540,1013],
	[120541,977],[120542,1008],[120543,981],[120544,1009],[120545,982],[120546,120562,'R',-119633],[120563,1012],
	[120564,120570,'R',-119633],[120571,8711],[120572,120596,'R',-119627],[120597,8706],[120598,1013],[120599,977],
	[120600,1008],[120601,981],[120602,1009],[120603,982],[120604,120620,'R',-119691],[120621,1012],
	[120622,120628,'R',-119691],[120629,8711],[120630,120654,'R',-119685],[120655,8706],[120656,1013],[120657,977],
	[120658,1008],[120659,981],[120660,1009],[120661,982],[120662,120678,'R',-119749],[120679,1012],
	[120680,120686,'R',-119749],[120687,8711],[120688,120712,'R',-119743],[120713,8706],[120714,1013],[120715,977],
	[120716,1008],[120717,981],[120718,1009],[120719,982],[120720,120736,'R',-119807],[120737,1012],
	[120738,120744,'R',-119807],[120745,8711],[120746,120770,'R',-119801],[120771,8706],[120772,1013],[120773,977],
	[120774,1008],[120775,981],[120776,1009],[120777,982],[120778,120779,'R',-119790],[120782,120791,'R',-120734],
	[120792,120801,'R',-120744],[120802,120811,'R',-120754],[120812,120821,'R',-120764],[120822,120831,'R',-120774],
	[126464,126465,'R',-124889],[126466,1580],[126467,1583],[126469,1608],[126470,1586],[126471,1581],[126472,1591],
	[126473,1610],[126474,126477,'R',-124871],[126478,1587],[126479,1593],[126480,1601],[126481,1589],[126482,1602],
	[126483,1585],[126484,1588],[126485,126486,'R',-124907],[126487,1582],[126488,1584],[126489,1590],[126490,1592],
	[126491,1594],[126492,1646],[126493,1722],[126494,1697],[126495,1647],[126497,1576],[126498,1580],[126500,1607],
	[126503,1581],[126505,1610],[126506,126509,'R',-124903],[126510,1587],[126511,1593],[126512,1601],[126513,1589],
	[126514,1602],[126516,1588],[126517,126518,'R',-124939],[126519,1582],[126521,1590],[126523,1594],[126530,1580],
	[126535,1581],[126537,1610],[126539,126541,'R',-124935],[126542,1587],[126543,1593],[126545,1589],[126546,1602],
	[126548,1588],[126551,1582],[126553,1590],[126555,1594],[126557,1722],[126559,1647],[126561,1576],[126562,1580],
	[126564,1607],[126567,1581],[126568,1591],[126569,1610],[126570,126573,'R',-124967],[126574,1587],[126575,1593],
	[126576,1601],[126577,1589],[126578,1602],[126580,1588],[126581,126582,'R',-125003],[126583,1582],[126585,1590],
	[126586,1592],[126587,1594],[126588,1646],[126590,1697],[126592,126593,'R',-125017],[126594,1580],[126595,1583],
	[126596,126597,'R',-124989],[126598,1586],[126599,1581],[126600,1591],[126601,1610],[126603,126605,'R',-124999],
	[126606,1587],[126607,1593],[126608,1601],[126609,1589],[126610,1602],[126611,1585],[126612,1588],
	[126613,126614,'R',-125035],[126615,1582],[126616,1584],[126617,1590],[126618,1592],[126619,1594],[126625,1576],
	[126626,1580],[126627,1583],[126629,1608],[126630,1586],[126631,1581],[126632,1591],[126633,1610],
	[126635,126637,'R',-125031],[126638,1587],[126639,1593],[126640,1601],[126641,1589],[126642,1602],[126643,1585],
	[126644,1588],[126645,126646,'R',-125067],[126647,1582],[126648,1584],[126649,1590],[126650,1592],[126651,1594],
	[127232,[48, 46]],[127233,[48, 44]],[127234,[49, 44]],[127235,[50, 44]],[127236,[51, 44]],[127237,[52, 44]],
	[127238,[53, 44]],[127239,[54, 44]],[127240,[55, 44]],[127241,[56, 44]],[127242,[57, 44]],[127248,[40, 65, 41]],
	[127249,[40, 66, 41]],[127250,[40, 67, 41]],[127251,[40, 68, 41]],[127252,[40, 69, 41]],[127253,[40, 70, 41]],
	[127254,[40, 71, 41]],[127255,[40, 72, 41]],[127256,[40, 73, 41]],[127257,[40, 74, 41]],[127258,[40, 75, 41]],
	[127259,[40, 76, 41]],[127260,[40, 77, 41]],[127261,[40, 78, 41]],[127262,[40, 79, 41]],[127263,[40, 80, 41]],
	[127264,[40, 81, 41]],[127265,[40, 82, 41]],[127266,[40, 83, 41]],[127267,[40, 84, 41]],[127268,[40, 85, 41]],
	[127269,[40, 86, 41]],[127270,[40, 87, 41]],[127271,[40, 88, 41]],[127272,[40, 89, 41]],[127273,[40, 90, 41]],
	[127274,[12308, 83, 12309]],[127275,67],[127276,82],[127277,[67, 68]],[127278,[87, 90]],[127280,127305,'R',-127215],
	[127306,[72, 86]],[127307,[77, 86]],[127308,[83, 68]],[127309,[83, 83]],[127310,[80, 80, 86]],[127311,[87, 67]],
	[127338,[77, 67]],[127339,[77, 68]],[127376,[68, 74]],[127488,[12411, 12363]],[127489,[12467, 12467]],[127490,12469],
	[127504,127506,'R',0],[127507,12487],[127508,127528,'R',0],[127529,19968],[127530,127546,'R',0],[127552,[12308, 12309]],
	[127553,[12308, 12309]],[127554,[12308, 12309]],[127555,[12308, 12309]],[127556,[12308, 12309]],[127557,[12308, 12309]],
	[127558,[12308, 12309]],[127559,[12308, 12309]],[127560,[12308, 12309]],[127568,195101,'R',0]];

var net = net||{};
net.kornr = net.kornr||{};
net.kornr.unicode= net.kornr.unicode||{}; 

(function(NAMESPACE) {
    "use strict";
	var CONST_GO_LEFT = -1;
	var CONST_GO_RIGHT = -2;

	/**
	 * Creates a searching function that memorizes the last found character index, to make same-codepage
	 * lookups efficient.
	 */
	function make_search_function_in_array(data) {
		
		var lastindex = 0;

		return function(c) {
			var index = lastindex;
			var r = data[index];
			var step = 1;
			var direction = 0;
			
			while (index >= 0 && index<data.length) {

				r = data[index];
				
				if (r instanceof Array) {
					if (c < r[0]) {
						step = -1;
					}  else if (c > r[1]) {
						step = +1
					} else {
						lastindex = index;
						return true;
					}
				} else {
					if (r == c) {
						lastindex = index;
						return true;
					}
					step = c<r?-1:+1;
				}
				
				if (direction == 0) {
					direction = step;
				} else if (direction != step) {
					return false;
				}
				index += step;
				
				if (index > data.length || index<0) {
					return false;
				}
			}
			return false;
		}

	}
		
	function create_category_lookup_function(data, originFile) {

		if (data === undefined) {
			return function() {
				throw "Missing data, you need to include " + originFile;
			}
		}

		var search_codepoint_in_array = make_search_function_in_array(data);
		
		return function(str) {
			switch(typeof str) {
			case "number":
				return search_codepoint_in_array(str);
				break;
			case "string":
				for (var i=0, max=str.length; i<max; ++i) {
					var a = search_codepoint_in_array(str.charCodeAt(i));
					if (a === false) {
						return false;
					}
				}
				return true;
			break;
			}
			return false;
		}
	}
	
	/**
	 * Creates a normalizer function for the given data array. The function memorizes the
	 * last codepoint converted, so that converting string containing characters from the
	 * same codepage is efficient. On the other side, the algorithm is not adapted to
	 * string mixing characters from different languages/codepages (another search function
	 * should be written for this case)
	 */
	function create_normalizer(data, originFile) {

		if (data === undefined) {
			return function() {
				throw "Missing data, you need to include " + originFile;
			}
		}
		
		//
		// Test a codepoint integer value against an index in the data array.
		// Returns:
		// - A positive integer or an array of integers if the codepoint matches
		// - CONST_GO_RIGHT if the index is too low
		// - CONST_GO_LEFT if the index is too high
		function normalizer_element_match(c,index) {
			if (index<0) {
				return CONST_GO_RIGHT;
			} else if (index>=data.length){
				return CONST_GO_LEFT;
			}
			
			var t = data[index];
			if (!t) { return false; }
			if (t.length == 2) {
				if (t[0] == c) {
					return t[1];
				}
			} else {
				if (t[0] <= c && t[1]>=c) {
					if (t[2] == 'R') {
						return c + t[3];
					} else {
						return t[3];
					}
				}
			}
			return t[0] > c?CONST_GO_LEFT : CONST_GO_RIGHT;
		}

		var normalize_char_last_index = 0;

		function normalize_char(c) {
			var index = normalize_char_last_index;
			var r = normalizer_element_match(c,index);
			if (r < 0) {
				// Need to search more...
				var direction = r;
				var step = direction==CONST_GO_RIGHT?+1:-1;
				while ( r === direction) {
					index += step;
					r = normalizer_element_match(c,index);
					if (!(r < 0)) { // a positive integer or an array
						normalize_char_last_index = index; // remember the last successful index for performance
						return r;
					}
				}
				normalize_char_last_index = index; // remember the last successful index for performance
				return c; // if not found, the codepoint is not in the array, so keep the same value
			} else {
				return r;
			}
		}
		
		return function(str) {
			var res = "";
			for (var i=0, max=str.length; i<max; ++i) {
				var a = normalize_char(str.charCodeAt(i));
				if (a instanceof Array) {
					for (var j=0; j<a.length; ++j) {
						res += String.fromCharCode(a[j]);
					}
				} else {
					res += String.fromCharCode(a);
				}
			}
			return res;
		};
	}	
	//
	// Converts a string to lowercase, then decompose it, and remove all diacritical marks
	NAMESPACE.lowercase_nomark = create_normalizer(NAMESPACE.norm_lowercase_nomark_data, "normalizer_lowercase_nomark.js");

	// Converts a string to lowercase, then decompose it (this is different from the String.toLowerCase, as the latter does not decompose the string)
	NAMESPACE.lowercase = create_normalizer(NAMESPACE.norm_lowercase_data, "normalizer_lowercase.js");

	// Converts a string to lowercase, then decompose it, and remove all diacritical marks
	NAMESPACE.uppercase_nomark = create_normalizer(NAMESPACE.norm_uppercase_nomark_data, "normalizer_uppercase_nomark.js");

	// Converts a string to lowercase, then decompose it (this is different from the String.toLowerCase, as the latter does not decompose the string)
	NAMESPACE.uppercase = create_normalizer(NAMESPACE.norm_uppercase_data, "normalizer_uppercase.js");

	NAMESPACE.is_letter = create_category_lookup_function(NAMESPACE.categ_letters_data, "categ_letters.js");
	NAMESPACE.is_letter_number = create_category_lookup_function(NAMESPACE.categ_letters_numbers_data, "categ_letters_numbers.js");
	NAMESPACE.is_number = create_category_lookup_function(NAMESPACE.categ_numbers_data, "categ_numbers.js");

	NAMESPACE.is_punct = create_category_lookup_function(NAMESPACE.categ_punct_data, "categ_puncts.js");
	NAMESPACE.is_separator = create_category_lookup_function(NAMESPACE.categ_separators_data, "categ_separators.js");
	NAMESPACE.is_punct_separator = create_category_lookup_function(NAMESPACE.categ_puncts_separators_data, "categ_puncts_separators_controls.js");
	NAMESPACE.is_punct_separator_control = create_category_lookup_function(NAMESPACE.categ_puncts_separators_controls_data, "categ_puncts_separators.js");
	
	
	NAMESPACE.is_control = create_category_lookup_function(NAMESPACE.categ_controls_data, "categ_controls.js");
	NAMESPACE.is_math = create_category_lookup_function(NAMESPACE.categ_maths_data, "categ_maths.js");
	NAMESPACE.is_currency = create_category_lookup_function(NAMESPACE.categ_currencies_data, "categ_currencies.js");
	
	return NAMESPACE;
})(net.kornr.unicode);
var fullproof = (function(NAMESPACE) {
	NAMESPACE.english = NAMESPACE.english|| {};
	
	
	/*
	Copyright (c) 2011, Chris Umbel

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
	*/
	/*
	 * Borrowed from https://github.com/NaturalNode/natural/blob/master/lib/natural/phonetics/metaphone.js
	 */

    NAMESPACE.english.metaphone_make = function(maxLength) {
        "use strict";

        function dedup(token) {
            return token.replace(/([^c])\1/g, '$1');
        }

        function dropInitialLetters(token) {
            if(token.match(/^(kn|gn|pn|ae|wr)/))
                return token.substr(1, token.length - 1);

            return token;
        }

        function dropBafterMAtEnd(token) {
            return token.replace(/mb$/, 'm');
        }

        function cTransform(token) {
            token = token.replace(/([^s]|^)(c)(h)/g, '$1x$3').trim();
            token = token.replace(/cia/g, 'xia');
            token = token.replace(/c(i|e|y)/g, 's$1');
            token = token.replace(/c/g, 'k');

            return token;
        }

        function dTransform(token) {
            token = token.replace(/d(ge|gy|gi)/g, 'j$1');
            token = token.replace(/d/g, 't');

            return token;
        }

        function dropG(token) {
            token = token.replace(/gh(^$|[^aeiou])/g, 'h$1');
            token = token.replace(/g(n|ned)$/g, '$1');

            return token;
        }

        function transformG(token) {
            token = token.replace(/([^g]|^)(g)(i|e|y)/g, '$1j$3');
            token = token.replace(/gg/g, 'g');
            token = token.replace(/g/g, 'k');

            return token;
        }

        function dropH(token) {
            return token.replace(/([aeiou])h([^aeiou])/g, '$1$2');
        }

        function transformCK(token) {
            return token.replace(/ck/g, 'k');
        }
        function transformPH(token) {
            return token.replace(/ph/g, 'f');
        }

        function transformQ(token) {
            return token.replace(/q/g, 'k');
        }

        function transformS(token) {
            return token.replace(/s(h|io|ia)/g, 'x$1');
        }

        function transformT(token) {
            token = token.replace(/t(ia|io)/g, 'x$1');
            token = token.replace(/th/, '0');

            return token;
        }

        function dropT(token) {
            return token.replace(/tch/g, 'ch');
        }

        function transformV(token) {
            return token.replace(/v/g, 'f');
        }

        function transformWH(token) {
            return token.replace(/^wh/, 'w');
        }

        function dropW(token) {
            return token.replace(/w([^aeiou]|$)/g, '$1');
        }

        function transformX(token) {
            token = token.replace(/^x/, 's');
            token = token.replace(/x/g, 'ks');
            return token;
        }

        function dropY(token) {
            return token.replace(/y([^aeiou]|$)/g, '$1');
        }

        function transformZ(token) {
            return token.replace(/z/, 's');
        }

        function dropVowels(token) {
            return token.charAt(0) + token.substr(1, token.length).replace(/[aeiou]/g, '');
        }

        return function(token, callback) {
            maxLength = maxLength || 32;
            token = token.toLowerCase();
            token = dedup(token);
            token = dropInitialLetters(token);
            token = dropBafterMAtEnd(token);
            token = transformCK(token);
            token = cTransform(token);
            token = dTransform(token);
            token = dropG(token);
            token = transformG(token);
            token = dropH(token);
            token = transformPH(token);
            token = transformQ(token);
            token = transformS(token);
            token = transformX(token);
            token = transformT(token);
            token = dropT(token);
            token = transformV(token);
            token = transformWH(token);
            token = dropW(token);
            token = dropY(token);
            token = transformZ(token);
            token = dropVowels(token);

            token.toUpperCase();
            if(token.length >= maxLength) {
                token = token.substring(0, maxLength);
            }
            token = token.toUpperCase();

            return callback?callback(token):token;
        };
    };

    NAMESPACE.english.metaphone = NAMESPACE.english.metaphone_make(32);

    return NAMESPACE;
})(fullproof||{});

var fullproof = (function(NAMESPACE) {
	
	NAMESPACE.english = NAMESPACE.english|| {};

	/**
	 * Porter stemmer adapted from http://code.google.com/p/yeti-witch/source/browse/trunk/lib/porter-stemmer.js
	 * Original license header below, declared as Apache License V2 on the project site
	 */
	/**
	 * 18 May 2008
	 * Stemming is the process for reducing inflected (or sometimes derived) words to their stem, base or root
	 * form. Porter stemming is designed for the English language.
	 * 
	 * This code has been slighly adapted from Martin Porter's examples.
	 *  - http://tartarus.org/~martin/PorterStemmer/
	 *  
	 * Please assume any errors found in the below code are translation errors
	 * inserted by myself and not those of the original authors.
	 *  
	 * @author Matt Chadburn <matt@commuterjoy.co.uk>
	 */
	NAMESPACE.english.porter_stemmer = (function(){
		"use strict";

		var step2list = new Array();
        step2list["ational"]="ate";
        step2list["tional"]="tion";
        step2list["enci"]="ence";
        step2list["anci"]="ance";
        step2list["izer"]="ize";
        step2list["bli"]="ble";
        step2list["alli"]="al";
        step2list["entli"]="ent";
        step2list["eli"]="e";
        step2list["ousli"]="ous";
        step2list["ization"]="ize";
        step2list["ation"]="ate";
        step2list["ator"]="ate";
        step2list["alism"]="al";
        step2list["iveness"]="ive";
        step2list["fulness"]="ful";
        step2list["ousness"]="ous";
        step2list["aliti"]="al";
        step2list["iviti"]="ive";
        step2list["biliti"]="ble";
        step2list["logi"]="log";
        
        var step3list = new Array();
        step3list["icate"]="ic";
        step3list["ative"]="";
        step3list["alize"]="al";
        step3list["iciti"]="ic";
        step3list["ical"]="ic";
        step3list["ful"]="";
        step3list["ness"]="";

        var c = "[^aeiou]";          // consonant
        var v = "[aeiouy]";          // vowel
        var C = c + "[^aeiouy]*";    // consonant sequence
        var V = v + "[aeiou]*";      // vowel sequence
        
        var mgr0 = "^(" + C + ")?" + V + C;               // [C]VC... is m>0
        var meq1 = "^(" + C + ")?" + V + C + "(" + V + ")?$";  // [C]VC[V] is m=1
        var mgr1 = "^(" + C + ")?" + V + C + V + C;       // [C]VCVC... is m>1
        var s_v   = "^(" + C + ")?" + v;                   // vowel in stem

        return function(word, callback) {
	        word = word.toLowerCase();

	        var stem;
	        var suffix;
	        var firstch;
	        var origword = w;
	        var w = word;
	        
	        if (word.length < 3) { return word; }
	
	        var re;
	        var re2;
	        var re3;
	        var re4;
	
	        firstch = word.substr(0,1);
	        if (firstch == "y") {
	                w = firstch.toUpperCase() + w.substr(1);
	        }
	
	        // Step 1a
	        re = /^(.+?)(ss|i)es$/;
	        re2 = /^(.+?)([^s])s$/;
	
	        if (re.test(w)) { w = w.replace(re,"$1$2"); }
	        else if (re2.test(w)) { w = w.replace(re2,"$1$2"); }
	
	        // Step 1b
	        re = /^(.+?)eed$/;
	        re2 = /^(.+?)(ed|ing)$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                re = new RegExp(mgr0);
	                if (re.test(fp[1])) {
	                        re = /.$/;
	                        w = w.replace(re,"");
	                }
	        } else if (re2.test(w)) {
	                var fp = re2.exec(w);
	                stem = fp[1];
	                re2 = new RegExp(s_v);
	                if (re2.test(stem)) {
	                        w = stem;
	                        re2 = /(at|bl|iz)$/;
	                        re3 = new RegExp("([^aeiouylsz])\\1$");
	                        re4 = new RegExp("^" + C + v + "[^aeiouwxy]$");
	                        if (re2.test(w)) {      w = w + "e"; }
	                        else if (re3.test(w)) { re = /.$/; w = w.replace(re,""); }
	                        else if (re4.test(w)) { w = w + "e"; }
	                }
	        }
	
	        // Step 1c
	        re = /^(.+?)y$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                stem = fp[1];
	                re = new RegExp(s_v);
	                if (re.test(stem)) { w = stem + "i"; }
	        }
	
	        // Step 2
	        re = /^(.+?)(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                stem = fp[1];
	                suffix = fp[2];
	                re = new RegExp(mgr0);
	                if (re.test(stem)) {
	                        w = stem + step2list[suffix];
	                }
	        }
	
	        // Step 3
	        re = /^(.+?)(icate|ative|alize|iciti|ical|ful|ness)$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                stem = fp[1];
	                suffix = fp[2];
	                re = new RegExp(mgr0);
	                if (re.test(stem)) {
	                        w = stem + step3list[suffix];
	                }
	        }
	
	        // Step 4
	        re = /^(.+?)(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/;
	        re2 = /^(.+?)(s|t)(ion)$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                stem = fp[1];
	                re = new RegExp(mgr1);
	                if (re.test(stem)) {
	                        w = stem;
	                }
	        } else if (re2.test(w)) {
	                var fp = re2.exec(w);
	                stem = fp[1] + fp[2];
	                re2 = new RegExp(mgr1);
	                if (re2.test(stem)) {
	                        w = stem;
	                }
	        }
	
	        // Step 5
	        re = /^(.+?)e$/;
	        if (re.test(w)) {
	                var fp = re.exec(w);
	                stem = fp[1];
	                re = new RegExp(mgr1);
	                re2 = new RegExp(meq1);
	                re3 = new RegExp("^" + C + v + "[^aeiouwxy]$");
	                if (re.test(stem) || (re2.test(stem) && !(re3.test(stem)))) {
	                        w = stem;
	                }
	        }
	
	        re = /ll$/;
	        re2 = new RegExp(mgr1);
	        if (re.test(w) && re2.test(w)) {
	                re = /.$/;
	                w = w.replace(re,"");
	        }
	
	        // and turn initial Y back to y
	
	        if (firstch == "y") {
	                w = firstch.toLowerCase() + w.substr(1);
	        }
	
	        return callback?callback(w):w;
        }
	})();

	return NAMESPACE;
})(fullproof||{});

var fullproof = (function(NAMESPACE) {
	
	NAMESPACE.english = NAMESPACE.english|| {};
	
	/**
	 * Stopword list, based on http://members.unine.ch/jacques.savoy/clef/
	 * Works for lowercased words.
	 */
	var stopwords = {
	    "a" : 1, "a's" : 1, "able" : 1, "about" : 1, "above" : 1, "according" : 1, "accordingly" : 1, "across" : 1,
	    "actually" : 1, "after" : 1, "afterwards" : 1, "again" : 1, "against" : 1, "ain't" : 1, "all" : 1, "allow" : 1,
	    "allows" : 1, "almost" : 1, "alone" : 1, "along" : 1, "already" : 1, "also" : 1, "although" : 1, "always" : 1,
	    "am" : 1, "among" : 1, "amongst" : 1, "an" : 1, "and" : 1, "another" : 1, "any" : 1, "anybody" : 1,
	    "anyhow" : 1, "anyone" : 1, "anything" : 1, "anyway" : 1, "anyways" : 1, "anywhere" : 1, "apart" : 1,
	    "appear" : 1, "appreciate" : 1, "appropriate" : 1, "are" : 1, "aren't" : 1, "around" : 1, "as" : 1,
	    "aside" : 1, "ask" : 1, "asking" : 1, "associated" : 1, "at" : 1, "available" : 1, "away" : 1, "awfully" : 1,
	    "b" : 1, "be" : 1, "became" : 1, "because" : 1, "become" : 1, "becomes" : 1, "becoming" : 1, "been" : 1,
	    "before" : 1, "beforehand" : 1, "behind" : 1, "being" : 1, "believe" : 1, "below" : 1, "beside" : 1,
	    "besides" : 1, "best" : 1, "better" : 1, "between" : 1, "beyond" : 1, "both" : 1, "brief" : 1, "but" : 1,
	    "by" : 1, "c" : 1, "c'mon" : 1, "c's" : 1, "came" : 1, "can" : 1, "can't" : 1, "cannot" : 1, "cant" : 1,
	    "cause" : 1, "causes" : 1, "certain" : 1, "certainly" : 1, "changes" : 1, "clearly" : 1, "co" : 1, "com" : 1,
	    "come" : 1, "comes" : 1, "concerning" : 1, "consequently" : 1, "consider" : 1, "considering" : 1,
	    "contain" : 1, "containing" : 1, "contains" : 1, "corresponding" : 1, "could" : 1, "couldn't" : 1,
	    "course" : 1, "currently" : 1, "d" : 1, "definitely" : 1, "described" : 1, "despite" : 1, "did" : 1,
	    "didn't" : 1, "different" : 1, "do" : 1, "does" : 1, "doesn't" : 1, "doing" : 1, "don't" : 1, "done" : 1,
	    "down" : 1, "downwards" : 1, "during" : 1, "e" : 1, "each" : 1, "edu" : 1, "eg" : 1, "eight" : 1, "either" : 1,
	    "else" : 1, "elsewhere" : 1, "enough" : 1, "entirely" : 1, "especially" : 1, "et" : 1, "etc" : 1, "even" : 1,
	    "ever" : 1, "every" : 1, "everybody" : 1, "everyone" : 1, "everything" : 1, "everywhere" : 1, "ex" : 1,
	    "exactly" : 1, "example" : 1, "except" : 1, "f" : 1, "far" : 1, "few" : 1, "fifth" : 1, "first" : 1,
	    "five" : 1, "followed" : 1, "following" : 1, "follows" : 1, "for" : 1, "former" : 1, "formerly" : 1,
	    "forth" : 1, "four" : 1, "from" : 1, "further" : 1, "furthermore" : 1, "g" : 1, "get" : 1, "gets" : 1,
	    "getting" : 1, "given" : 1, "gives" : 1, "go" : 1, "goes" : 1, "going" : 1, "gone" : 1, "got" : 1,
	    "gotten" : 1, "greetings" : 1, "h" : 1, "had" : 1, "hadn't" : 1, "happens" : 1, "hardly" : 1, "has" : 1,
	    "hasn't" : 1, "have" : 1, "haven't" : 1, "having" : 1, "he" : 1, "he's" : 1, "hello" : 1, "help" : 1,
	    "hence" : 1, "her" : 1, "here" : 1, "here's" : 1, "hereafter" : 1, "hereby" : 1, "herein" : 1, "hereupon" : 1,
	    "hers" : 1, "herself" : 1, "hi" : 1, "him" : 1, "himself" : 1, "his" : 1, "hither" : 1, "hopefully" : 1,
	    "how" : 1, "howbeit" : 1, "however" : 1, "i" : 1, "i'd" : 1, "i'll" : 1, "i'm" : 1, "i've" : 1, "ie" : 1,
	    "if" : 1, "ignored" : 1, "immediate" : 1, "in" : 1, "inasmuch" : 1, "inc" : 1, "indeed" : 1, "indicate" : 1,
	    "indicated" : 1, "indicates" : 1, "inner" : 1, "insofar" : 1, "instead" : 1, "into" : 1, "inward" : 1,
	    "is" : 1, "isn't" : 1, "it" : 1, "it'd" : 1, "it'll" : 1, "it's" : 1, "its" : 1, "itself" : 1, "j" : 1,
	    "just" : 1, "k" : 1, "keep" : 1, "keeps" : 1, "kept" : 1, "know" : 1, "knows" : 1, "known" : 1, "l" : 1,
	    "last" : 1, "lately" : 1, "later" : 1, "latter" : 1, "latterly" : 1, "least" : 1, "less" : 1, "lest" : 1,
	    "let" : 1, "let's" : 1, "like" : 1, "liked" : 1, "likely" : 1, "little" : 1, "look" : 1, "looking" : 1,
	    "looks" : 1, "ltd" : 1, "m" : 1, "mainly" : 1, "many" : 1, "may" : 1, "maybe" : 1, "me" : 1, "mean" : 1,
	    "meanwhile" : 1, "merely" : 1, "might" : 1, "more" : 1, "moreover" : 1, "most" : 1, "mostly" : 1, "much" : 1,
	    "must" : 1, "my" : 1, "myself" : 1, "n" : 1, "name" : 1, "namely" : 1, "nd" : 1, "near" : 1, "nearly" : 1,
	    "necessary" : 1, "need" : 1, "needs" : 1, "neither" : 1, "never" : 1, "nevertheless" : 1, "new" : 1,
	    "next" : 1, "nine" : 1, "no" : 1, "nobody" : 1, "non" : 1, "none" : 1, "noone" : 1, "nor" : 1, "normally" : 1,
	    "not" : 1, "nothing" : 1, "novel" : 1, "now" : 1, "nowhere" : 1, "o" : 1, "obviously" : 1, "of" : 1, "off" : 1,
	    "often" : 1, "oh" : 1, "ok" : 1, "okay" : 1, "old" : 1, "on" : 1, "once" : 1, "one" : 1, "ones" : 1,
	    "only" : 1, "onto" : 1, "or" : 1, "other" : 1, "others" : 1, "otherwise" : 1, "ought" : 1, "our" : 1,
	    "ours" : 1, "ourselves" : 1, "out" : 1, "outside" : 1, "over" : 1, "overall" : 1, "own" : 1, "p" : 1,
	    "particular" : 1, "particularly" : 1, "per" : 1, "perhaps" : 1, "placed" : 1, "please" : 1, "plus" : 1,
	    "possible" : 1, "presumably" : 1, "probably" : 1, "provides" : 1, "q" : 1, "que" : 1, "quite" : 1, "qv" : 1,
	    "r" : 1, "rather" : 1, "rd" : 1, "re" : 1, "really" : 1, "reasonably" : 1, "regarding" : 1, "regardless" : 1,
	    "regards" : 1, "relatively" : 1, "respectively" : 1, "right" : 1, "s" : 1, "said" : 1, "same" : 1, "saw" : 1,
	    "say" : 1, "saying" : 1, "says" : 1, "second" : 1, "secondly" : 1, "see" : 1, "seeing" : 1, "seem" : 1,
	    "seemed" : 1, "seeming" : 1, "seems" : 1, "seen" : 1, "self" : 1, "selves" : 1, "sensible" : 1, "sent" : 1,
	    "serious" : 1, "seriously" : 1, "seven" : 1, "several" : 1, "shall" : 1, "she" : 1, "should" : 1,
	    "shouldn't" : 1, "since" : 1, "six" : 1, "so" : 1, "some" : 1, "somebody" : 1, "somehow" : 1, "someone" : 1,
	    "something" : 1, "sometime" : 1, "sometimes" : 1, "somewhat" : 1, "somewhere" : 1, "soon" : 1, "sorry" : 1,
	    "specified" : 1, "specify" : 1, "specifying" : 1, "still" : 1, "sub" : 1, "such" : 1, "sup" : 1, "sure" : 1,
	    "t" : 1, "t's" : 1, "take" : 1, "taken" : 1, "tell" : 1, "tends" : 1, "th" : 1, "than" : 1, "thank" : 1,
	    "thanks" : 1, "thanx" : 1, "that" : 1, "that's" : 1, "thats" : 1, "the" : 1, "their" : 1, "theirs" : 1,
	    "them" : 1, "themselves" : 1, "then" : 1, "thence" : 1, "there" : 1, "there's" : 1, "thereafter" : 1,
	    "thereby" : 1, "therefore" : 1, "therein" : 1, "theres" : 1, "thereupon" : 1, "these" : 1, "they" : 1,
	    "they'd" : 1, "they'll" : 1, "they're" : 1, "they've" : 1, "think" : 1, "third" : 1, "this" : 1,
	    "thorough" : 1, "thoroughly" : 1, "those" : 1, "though" : 1, "three" : 1, "through" : 1, "throughout" : 1,
	    "thru" : 1, "thus" : 1, "to" : 1, "together" : 1, "too" : 1, "took" : 1, "toward" : 1, "towards" : 1,
	    "tried" : 1, "tries" : 1, "truly" : 1, "try" : 1, "trying" : 1, "twice" : 1, "two" : 1, "u" : 1, "un" : 1,
	    "under" : 1, "unfortunately" : 1, "unless" : 1, "unlikely" : 1, "until" : 1, "unto" : 1, "up" : 1, "upon" : 1,
	    "us" : 1, "use" : 1, "used" : 1, "useful" : 1, "uses" : 1, "using" : 1, "usually" : 1, "uucp" : 1, "v" : 1,
	    "value" : 1, "various" : 1, "very" : 1, "via" : 1, "viz" : 1, "vs" : 1, "w" : 1, "want" : 1, "wants" : 1,
	    "was" : 1, "wasn't" : 1, "way" : 1, "we" : 1, "we'd" : 1, "we'll" : 1, "we're" : 1, "we've" : 1, "welcome" : 1,
	    "well" : 1, "went" : 1, "were" : 1, "weren't" : 1, "what" : 1, "what's" : 1, "whatever" : 1, "when" : 1,
	    "whence" : 1, "whenever" : 1, "where" : 1, "where's" : 1, "whereafter" : 1, "whereas" : 1, "whereby" : 1,
	    "wherein" : 1, "whereupon" : 1, "wherever" : 1, "whether" : 1, "which" : 1, "while" : 1, "whither" : 1,
	    "who" : 1, "who's" : 1, "whoever" : 1, "whole" : 1, "whom" : 1, "whose" : 1, "why" : 1, "will" : 1,
	    "willing" : 1, "wish" : 1, "with" : 1, "within" : 1, "without" : 1, "won't" : 1, "wonder" : 1, "would" : 1,
	    "wouldn't" : 1, "x" : 1, "y" : 1, "yes" : 1, "yet" : 1, "you" : 1, "you'd" : 1, "you'll" : 1,
	    "you're" : 1, "you've" : 1, "your" : 1, "yours" : 1, "yourself" : 1, "yourselves" : 1, "z" : 1, "zero" : 1 };

	NAMESPACE.english.stopword_remover = function(word, callback) {
		return NAMESPACE.normalizer.filter_in_object(word, stopwords, callback);
	};
	
	return NAMESPACE;
})(fullproof||{});

var fullproof = (function(NAMESPACE) {
    "use strict";

    NAMESPACE.french = NAMESPACE.french||{};

    NAMESPACE.french.simpleform = (function(){

        var suffix_removals_verbs_raw = [
            // Below, common verbs suffix first
            [/.../, /er(ai([st]?|ent)|i?(on[ts]|ez))$/, "e"],
            [/.../, /ass(i?(ez?|ons)|e(nt|s)?)$/, "e"], // asse, asses, assez, assiez, assies*, if root length >= 3
            [/.../, /assions$/, "e"], // assions if root lengh>=3
            [/.../, /assent$/, "e"],   // assent if root lengh>=3

            [/endr(ez?|ai[st]?|on[st])$/, "ã"],		// endrez, endrai, endrais, endrait, endrons, endront

            [/.../, /iss(i?(ons|ez)|ai[st]?|ant(es?)?|es?)$/, "" ], // issions, issiez, issais, issait, issai, issant, issante, issantes, isses

            [/irai(s|(en)?t)?$/, ""], // irai, irait, irais, iraient

            [/.../, /e?oi(re?|t|s|ent)$/, ""],  // eoir, eoire, oir, oire, oit, ois, oient

            [/.../, /aient$/, ""],     // removes aient
            [/.../, /a[mt]es$/, ""], // removes ames, ates
            [/i?ons$/, ""],   // removes ons, ions
            [/ait$/, ""],     // removes ait
            [/ent$/, ""],     // removes ent
            [/i?e[rz]$/, "e"] // removes er, ez, iez

        ];

        var suffix_removals_nouns_raw = [
            [/inages?$/, "1"],	// "copinage" > "cop1"
            [/.../, /ages?$/, ""], // "habillage" > "habill"
            [/.../, /[aoie]tions?$/, ""], // "déclaration" > "déclar", not "nation"
            [/og(ies?|ues?)$/, "og"], // "philologie" -> "philolog", "philologue" -> "philolog"
            [/t(rices?|euses?)$/, "ter"], // "fédératrice" -> "fédérater","flatteuse" -> "flatter" (eur is -> er by another rule)
            [/.../, /e(uses?|ries?|urs?)$/, "er"], // euse, euses, eries, eries, eur (flatteuse, flatterie, flatteur)
            [/utions$/, "u"], // "pollution", "attribution" ! produces a "u", because "uer"$ is not removed (but "er"$ is).
            [/[ae]n[cs]es?$/, "ãS"], // prudence" -> "prudã", "tolérance" -> "tolérã"
            [/..al/, /ites?$/, ""], // // "anormalite" -> "anormal"
            [/[ea]mment/, "ã"], // prudemment -> "prudã"
            //
            //not processed:
            //* usion$ : not an interesting simplification, as there are not
            //  enough nominal cases. i.e. "diffusion", but "illusion",
            // "exclusion", "contusion", etc.
            [/ives?$/, "if"], // // "consécutives" -> con
            [/istes?$/, "isme"], // maybe a bit aggressive ?
            [/ables?$/, ""], // "chiffrable" -> "chiffr". aggressive ?
            [/[^ae]/, /ines?$/, "1"] // "citadine"->"citadin"
        ];

        var phonetic_transforms_raw = [

            [/n/, /t/, /iel/, "S"],
            [false, /t/, /i[oea]/, "S"],

            // the A LETTER
            [false, /ain/, /[^aeiouymn].*|$/, "1" ], // copain->cop1, complainte->compl1te
            [/ai(s$)?/, "e"],
            [false, /am/, /[^aeiouymn].*|$/, "ã" ], //  crampe->crãpe
            [/aux?$/, "al"], // tribunaux->tribunal
            [/e?au(x$)?/, "o"], // beaux->bo, bateau->bato, journaux->journo
            [/an(te?s?|s)$/, "ã"], //
            [false, /an/, /[^aeiouymn].*|$/, "ã" ],
            [/r[dt]s?$/, "r"],
            // Process the e letter
            // The e letter is probably the most complicated of all
            [false, /ein/, /[^aeiouymn].*|$/, "1"], // frein, teint
            [/e[ui]/, "e"],// peine, pleurer, bleu
            [/en[td]$/, "ã"], // client, prend, fend
            [/i/, /en/, /[^aeiouymn].*|$/, "1"], // norvégien, rien
            [false, /en/, /[^aeiouymn].*|$/, "ã"], // tente->tãte
            [/ets?$/, "e"], // violet, triplets
            [false, /e/, /o/, ""], // like surseoir

            // Process the i letter

            [/ier(s|es?)?$/, ""], // ier, iere, iere, ieres
            [false, /i[nm]/, /[^aeiouymn].*|$/, "1"], // malintentionné->mal1tentionné
            [/ill/, "y"], // paille->paye, rouille->rouye

            // Process the o letter
            [false, /on/, /[^aeiouyhnm].*|$/, "ô"],
            [false, /ouin/, /[^aeiouymn].*|$/, "o1"],
            [/oe(u(d$)?)?/, "e"],

            // Process the u letter
            [false, /un/, /[^aeiouymn].*|$/, "1"],
            [/u[st]$/, "u"], // "résidus", "crut" TODO better remove /[st]$/ ?

            // Process the y letter
            [/yer$/, "i"], // "ennuyer"->ennui, "appuyer"->appui
            [/[^aeiouy]/, /ym/, /[^aeiouy].*|$/, "1"], // "symbole", "nymphe", "sympa"
            [/[^aeiouy]/, /yn/, /[^aeiouynm].*|$/, "1"], // "syndicat", "synchro"
            [/[^aeiouy]/, /y/, "i"],  // "dynamite"

            [/[aeiouy]/, /s/, /[aeiouy]/, "z"],
            [/sc?h/, "ch"],

            [/gu/, "g"],
            [false, /g/, /[^aorl].*/, "j"],

            [/ph/, "f"],
            [/[^t]/, /t/, /ion/, "ss"],

            [/qu?/, "k"],
            [false, /c/, /[auorlt]/, "k"],

            [/[aeiou]/, /s/, /[aeiou]/, "z"],
            [/[^c]/, /h/, ""],
            [/^h/, ""],

            [/[oiua]/, /t$/, false, ""],

            [/es?$/, ""], // final e

            //plural
            [/[xs]$/, ""]

        ];

        function post_process_arrays(arr) {
            var result = [];
            for (var i=0; i<arr.length; ++i) {
                var obj = arr[i];
                if (obj) {
                    switch(obj.length) {
                        case 2:
                            result.push([new RegExp("(.*)("+obj[0].source+")(.*)"),obj[1]]);
                            break;
                        case 3:
                            result.push([new RegExp( (obj[0]?"(.*"+obj[0].source+")":"(.*)") + "("+obj[1].source+")" + "(.*)"),obj[2]]);
                            break;
                        case 4:
                            result.push([new RegExp( (obj[0]?"(.*"+obj[0].source+")":"(.*)") + "("+obj[1].source+")" + (obj[2]?"("+obj[2].source+".*)":"(.*)")),obj[3]]);
                            break;
                    }
                }
            }
            return result;
        }

        var suffix_removals_verbs = post_process_arrays(suffix_removals_verbs_raw);
        var suffix_removals_nouns = post_process_arrays(suffix_removals_nouns_raw);
        var phonetic_transforms = post_process_arrays(phonetic_transforms_raw);

        function apply_regexp_array(word, regarray, stopOnFirstMatch) {
//            var org = word;
//			console.log("==== applying rules on " + word + " ========");

            for (var i=0; i<regarray.length; ++i) {

                var res = regarray[i][0].exec(word);
                if (res) {
//					console.log("matched rule " + regarray[i][0].source + " -> " + regarray[i][1] + ", length: " + res.length);
//					console.log("re: " + regarray[i][0].lastIndex + " / " + res.index);
//					console.log(res);

                    var p1 = res[1];
                    var p2 = regarray[i][1];
                    var p3 = res[res.length-1];
                    word = p1 + p2 + p3;

//					console.log("word is now " + word + "  (" + p1 +" + " + p2 + " + " + p3 + "), before: " + org);

                    if (stopOnFirstMatch) {
                        i = regarray.length;
                    }
                }
            }
            return word;
        }


        return function(word, verbs, nouns, phonetic) {
            verbs = verbs===undefined?true:verbs;
            nouns = nouns===undefined?true:nouns;
            phonetic = phonetic===undefined?true:phonetic;

            if (verbs) {
                word = apply_regexp_array(word, suffix_removals_verbs, true);
            }
            if (nouns) {
                word = apply_regexp_array(word, suffix_removals_nouns, true);
            }
            if (phonetic) {
                word = apply_regexp_array(word, phonetic_transforms, false);
            }
            return NAMESPACE.normalizer.remove_duplicate_letters(word.toLowerCase());
        };
    })();

    return NAMESPACE;
})(fullproof||{});
var fullproof = (function(NAMESPACE) {

	NAMESPACE.french = NAMESPACE.french||{};
	
	/**
	 * Stopword list, based on http://members.unine.ch/jacques.savoy/clef/
	 * Works for lowercased words, with or without diacritical marks
	 */
	var stopwords = {
	    "a" : 1, "à" : 1, "â" : 1, "abord" : 1, "afin" : 1, "ah" : 1, "ai" : 1, "aie" : 1, "ainsi" : 1, "allaient" : 1,
	    "allo" : 1, "allô" : 1, "allons" : 1, "après" : 1, "apres" : 1, "assez" : 1, "attendu" : 1, "au" : 1,
	    "aucun" : 1, "aucune" : 1, "aujourd" : 1, "aujourd'hui" : 1, "auquel" : 1, "aura" : 1, "auront" : 1,
	    "aussi" : 1, "autre" : 1, "autres" : 1, "aux" : 1, "auxquelles" : 1, "auxquels" : 1, "avaient" : 1,
	    "avais" : 1, "avait" : 1, "avant" : 1, "avec" : 1, "avoir" : 1, "ayant" : 1, "b" : 1, "bah" : 1,
	    "beaucoup" : 1, "bien" : 1, "bigre" : 1, "boum" : 1, "bravo" : 1, "brrr" : 1, "c" : 1, "ça" : 1, "ca" : 1,
	    "car" : 1, "ce" : 1, "ceci" : 1, "cela" : 1, "celle" : 1, "celle-ci" : 1, "celle-là" : 1, "celle-la" : 1,
	    "celles" : 1, "celles-ci" : 1, "celles-là" : 1, "celles-la" : 1, "celui" : 1, "celui-ci" : 1, "celui-là" : 1,
	    "celui-la" : 1, "cent" : 1, "cependant" : 1, "certain" : 1, "certaine" : 1, "certaines" : 1, "certains" : 1,
	    "certes" : 1, "ces" : 1, "cet" : 1, "cette" : 1, "ceux" : 1, "ceux-ci" : 1, "ceux-là" : 1, "ceux-la" : 1,
	    "chacun" : 1, "chaque" : 1, "cher" : 1, "chère" : 1, "chères" : 1, "chere" : 1, "cheres" : 1, "chers" : 1,
	    "chez" : 1, "chiche" : 1, "chut" : 1, "ci" : 1, "cinq" : 1, "cinquantaine" : 1, "cinquante" : 1,
	    "cinquantième" : 1, "cinquieme" : 1, "cinquantieme" : 1, "cinquième" : 1, "clac" : 1, "clic" : 1,
	    "combien" : 1, "comme" : 1, "comment" : 1, "compris" : 1, "concernant" : 1, "contre" : 1, "couic" : 1,
	    "crac" : 1, "d" : 1, "da" : 1, "dans" : 1, "de" : 1, "debout" : 1, "dedans" : 1, "dehors" : 1, "delà" : 1,
	    "dela" : 1, "depuis" : 1, "derrière" : 1, "derriere" : 1, "des" : 1, "dès" : 1, "désormais" : 1,
	    "desormais" : 1, "desquelles" : 1, "desquels" : 1, "dessous" : 1, "dessus" : 1, "deux" : 1, "deuxième" : 1,
	    "deuxièmement" : 1, "deuxieme" : 1, "deuxiemement" : 1, "devant" : 1, "devers" : 1, "devra" : 1,
	    "différent" : 1, "différente" : 1, "différentes" : 1, "différents" : 1, "different" : 1, "differente" : 1,
	    "differentes" : 1, "differents" : 1, "dire" : 1, "divers" : 1, "diverse" : 1, "diverses" : 1, "dix" : 1,
	    "dix-huit" : 1, "dixième" : 1, "dixieme" : 1, "dix-neuf" : 1, "dix-sept" : 1, "doit" : 1, "doivent" : 1,
	    "donc" : 1, "dont" : 1, "douze" : 1, "douzième" : 1, "douzieme" : 1, "dring" : 1, "du" : 1, "duquel" : 1,
	    "durant" : 1, "e" : 1, "effet" : 1, "eh" : 1, "elle" : 1, "elle-même" : 1, "elle-meme" : 1, "elles" : 1,
	    "elles-mêmes" : 1, "elles-memes" : 1, "en" : 1, "encore" : 1, "entre" : 1, "envers" : 1, "environ" : 1,
	    "es" : 1, "ès" : 1, "est" : 1, "et" : 1, "etant" : 1, "étaient" : 1, "étais" : 1, "était" : 1, "étant" : 1,
	    "etaient" : 1, "etais" : 1, "etait" : 1, "etc" : 1, "été" : 1, "ete" : 1, "etre" : 1, "être" : 1,
	    "eu" : 1, "euh" : 1, "eux" : 1, "eux-mêmes" : 1, "eux-memes" : 1, "excepté" : 1, "excepte" : 1, "f" : 1,
	    "façon" : 1, "facon" : 1, "fais" : 1, "faisaient" : 1, "faisant" : 1, "fait" : 1, "feront" : 1, "fi" : 1,
	    "flac" : 1, "floc" : 1, "font" : 1, "g" : 1, "gens" : 1, "h" : 1, "ha" : 1, "hé" : 1, "he" : 1, "hein" : 1,
	    "hélas" : 1, "helas" : 1, "hem" : 1, "hep" : 1, "hi" : 1, "ho" : 1, "holà" : 1, "hola" : 1, "hop" : 1,
	    "hormis" : 1, "hors" : 1, "hou" : 1, "houp" : 1, "hue" : 1, "hui" : 1, "huit" : 1, "huitième" : 1,
	    "huitieme" : 1, "hum" : 1, "hurrah" : 1, "i" : 1, "il" : 1, "ils" : 1, "importe" : 1, "j" : 1, "je" : 1,
	    "jusqu" : 1, "jusque" : 1, "k" : 1, "l" : 1, "la" : 1, "là" : 1, "la" : 1, "laquelle" : 1, "las" : 1, "le" : 1,
	    "lequel" : 1, "les" : 1, "lès" : 1, "lesquelles" : 1, "lesquels" : 1, "leur" : 1, "leurs" : 1, "longtemps" : 1,
	    "lorsque" : 1, "lui" : 1, "lui-même" : 1, "lui-meme" : 1, "m" : 1, "ma" : 1, "maint" : 1, "mais" : 1,
	    "malgré" : 1, "malgre" : 1, "me" : 1, "même" : 1, "mêmes" : 1, "meme" : 1, "memes" : 1, "merci" : 1, "mes" : 1,
	    "mien" : 1, "mienne" : 1, "miennes" : 1, "miens" : 1, "mille" : 1, "mince" : 1, "moi" : 1, "moi-même" : 1,
	    "moi-meme" : 1, "moins" : 1, "mon" : 1, "moyennant" : 1, "n" : 1, "na" : 1, "ne" : 1, "néanmoins" : 1,
	    "neanmoins" : 1, "neuf" : 1, "neuvième" : 1, "neuvieme" : 1, "ni" : 1, "nombreuses" : 1, "nombreux" : 1,
	    "non" : 1, "nos" : 1, "notre" : 1, "nôtre" : 1, "nôtres" : 1, "notres" : 1, "nous" : 1,
	    "nous-mêmes" : 1, "nous-memes" : 1, "nul" : 1, "o" : 1, "o|" : 1, "ô" : 1, "oh" : 1, "ohé" : 1, "olé" : 1,
	    "ollé" : 1, "ohe" : 1, "ole" : 1, "olle" : 1, "on" : 1, "ont" : 1, "onze" : 1, "onzième" : 1, "onzieme" : 1,
	    "ore" : 1, "ou" : 1, "où" : 1, "ouf" : 1, "ouias" : 1, "oust" : 1, "ouste" : 1, "outre" : 1, "p" : 1,
	    "paf" : 1, "pan" : 1, "par" : 1, "parmi" : 1, "partant" : 1, "particulier" : 1, "particulière" : 1,
	    "particulièrement" : 1, "particuliere" : 1, "particulierement" : 1, "pas" : 1, "passé" : 1, "passe" : 1,
	    "pendant" : 1, "personne" : 1, "peu" : 1, "peut" : 1, "peuvent" : 1, "peux" : 1, "pff" : 1, "pfft" : 1,
	    "pfut" : 1, "pif" : 1, "plein" : 1, "plouf" : 1, "plus" : 1, "plusieurs" : 1, "plutôt" : 1, "plutot" : 1,
	    "pouah" : 1, "pour" : 1, "pourquoi" : 1, "premier" : 1, "première" : 1, "premièrement" : 1, "près" : 1,
	    "premiere" : 1, "premierement" : 1, "pres" : 1, "proche" : 1, "psitt" : 1, "puisque" : 1, "q" : 1, "qu" : 1,
	    "quand" : 1, "quant" : 1, "quanta" : 1, "quant-à-soi" : 1, "quant-a-soi" : 1, "quarante" : 1, "quatorze" : 1,
	    "quatre" : 1, "quatre-vingt" : 1, "quatrième" : 1, "quatrièmement" : 1, "quatrieme" : 1, "quatriemement" : 1,
	    "que" : 1, "quel" : 1, "quelconque" : 1, "quelle" : 1, "quelles" : 1, "quelque" : 1, "quelques" : 1,
	    "quelqu'un" : 1, "quels" : 1, "qui" : 1, "quiconque" : 1, "quinze" : 1, "quoi" : 1, "quoique" : 1, "r" : 1,
	    "revoici" : 1, "revoilà" : 1, "revoila" : 1, "rien" : 1, "s" : 1, "sa" : 1, "sacrebleu" : 1, "sans" : 1,
	    "sapristi" : 1, "sauf" : 1, "se" : 1, "seize" : 1, "selon" : 1, "sept" : 1, "septième" : 1, "septieme" : 1,
	    "sera" : 1, "seront" : 1, "ses" : 1, "si" : 1, "sien" : 1, "sienne" : 1, "siennes" : 1, "siens" : 1,
	    "sinon" : 1, "six" : 1, "sixième" : 1, "sixieme" : 1, "soi" : 1, "soi-même" : 1, "soi-meme" : 1, "soit" : 1,
	    "soixante" : 1, "son" : 1, "sont" : 1, "sous" : 1, "stop" : 1, "suis" : 1, "suivant" : 1, "sur" : 1,
	    "surtout" : 1, "t" : 1, "ta" : 1, "tac" : 1, "tant" : 1, "te" : 1, "té" : 1, "te" : 1, "tel" : 1, "telle" : 1,
	    "tellement" : 1, "telles" : 1, "tels" : 1, "tenant" : 1, "tes" : 1, "tic" : 1, "tien" : 1, "tienne" : 1,
	    "tiennes" : 1, "tiens" : 1, "toc" : 1, "toi" : 1, "toi-même" : 1, "toi-meme" : 1, "ton" : 1, "touchant" : 1,
	    "toujours" : 1, "tous" : 1, "tout" : 1, "toute" : 1, "toutes" : 1, "treize" : 1, "trente" : 1, "très" : 1,
	    "tres" : 1, "trois" : 1, "troisième" : 1, "troisièmement" : 1, "troisieme" : 1, "troisiemement" : 1,
	    "trop" : 1, "tsoin" : 1, "tsouin" : 1, "tu" : 1, "u" : 1, "un" : 1, "une" : 1, "unes" : 1, "uns" : 1, "v" : 1,
	    "va" : 1, "vais" : 1, "vas" : 1, "vé" : 1, "ve" : 1, "vers" : 1, "via" : 1, "vif" : 1, "vifs" : 1, "vingt" : 1,
	    "vivat" : 1, "vive" : 1, "vives" : 1, "vlan" : 1, "voici" : 1, "voilà" : 1, "voila" : 1, "vont" : 1, "vos" : 1,
	    "votre" : 1, "vôtre" : 1, "vôtres" : 1, "votre" : 1, "votres" : 1, "vous" : 1, "vous-mêmes" : 1,
	    "vous-memes" : 1, "vu" : 1, "w" : 1, "x" : 1, "y" : 1, "z" : 1, "zut" : 1 };
	
	NAMESPACE.french.stopword_remover = function(word, callback) {
		return NAMESPACE.filter_in_object(word, stopwords, callback);
	};
	
	return NAMESPACE;
})(fullproof||{});
