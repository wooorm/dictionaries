declare namespace load {
  interface Dictionary {
    /**
     * A buffer for the affix file at `index.aff` in UTF-8.
     */
    aff: Buffer

    /**
     * A buffer for the dictionary file at `index.dic` in UTF-8.
     */
    dic: Buffer
  }

  type Callback = (error: NodeJS.ErrnoException | null, result: Dictionary) => void;
}

/**
 * Load the dictionary.
 */
declare const load: (callback: load.Callback) => void

export = load
