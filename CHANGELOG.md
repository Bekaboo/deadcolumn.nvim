# Changelog

## [1.0.1](https://github.com/Bekaboo/deadcolumn.nvim/compare/v1.0.0...v1.0.1) (2024-10-25)


### Bug Fixes

* **configs:** error calculating length of blobs ([#23](https://github.com/Bekaboo/deadcolumn.nvim/issues/23)) ([42466f3](https://github.com/Bekaboo/deadcolumn.nvim/commit/42466f358e962bccd31647de92ea3053cd950db7))
* **configs:** migrate to vim.islist as vim.tbl_islist is deprecated ([#27](https://github.com/Bekaboo/deadcolumn.nvim/issues/27)) ([9b7e849](https://github.com/Bekaboo/deadcolumn.nvim/commit/9b7e849e8543690aaf89ee595f6b13fa456690bd))

## [1.0.0](https://github.com/Bekaboo/deadcolumn.nvim/compare/v0.0.0...v1.0.0) (2024-02-18)


### ⚠ BREAKING CHANGES

* use `winhl` instead of setting `cc` directly

### Features

* **config:** allow passing callback function to opts.modes ([bc1bdc1](https://github.com/Bekaboo/deadcolumn.nvim/commit/bc1bdc138ed827000c8ffd58ac5cb98ec87110fe))
* **config:** allow passing callback function to opts.scope ([#12](https://github.com/Bekaboo/deadcolumn.nvim/issues/12)) ([8f19d5f](https://github.com/Bekaboo/deadcolumn.nvim/commit/8f19d5fba835689d1c777a9ca697aae058739360))
* **config:** allow setting offset for warning ([1c35515](https://github.com/Bekaboo/deadcolumn.nvim/commit/1c35515d469d5911d5afd1a027beeed6e6292b10))
* **deadcolumn:** expose modules in deadcolumn.lua ([42e44ff](https://github.com/Bekaboo/deadcolumn.nvim/commit/42e44ff2ec85f878942faf68b2a3ff631841697f))
* handle special cases when &termguicolors is not set ([#13](https://github.com/Bekaboo/deadcolumn.nvim/issues/13)) ([6c1f35c](https://github.com/Bekaboo/deadcolumn.nvim/commit/6c1f35c60f1d7766776d03c75bfd1ef77d6fda4e))
* **lsp:** add .luarc.json ([7f62f2f](https://github.com/Bekaboo/deadcolumn.nvim/commit/7f62f2ff8c3b03ea793278a3ec13b1ead2b49da1))


### Bug Fixes

* &cc not set to follow &tw in new buffers ([c6d612d](https://github.com/Bekaboo/deadcolumn.nvim/commit/c6d612d16ed1cca46f78c02af965b7a32c05448f))
* `get_hl_hex()` not padding hex color codes ([#15](https://github.com/Bekaboo/deadcolumn.nvim/issues/15)) ([4bec1fa](https://github.com/Bekaboo/deadcolumn.nvim/commit/4bec1fa65234ad5047b957356fb4a5e100cb83ea))
* `nvim_get_hl()` does not have `create` key on nvim 0.9.5 ([#17](https://github.com/Bekaboo/deadcolumn.nvim/issues/17)) ([b84cdf2](https://github.com/Bekaboo/deadcolumn.nvim/commit/b84cdf2fc94c59651ececd5e4d2a0488b38a7a75))
* `opts.scope` is ignored ([0b27192](https://github.com/Bekaboo/deadcolumn.nvim/commit/0b271926037153e7aa69bfab366ff8749ebba521))
* `opts.warning.offset` ignored ([acc37e1](https://github.com/Bekaboo/deadcolumn.nvim/commit/acc37e1a27c19df030cb824297885172e0f29ceb))
* **configs:** error when using 'buffer' scope in empty buffer ([#16](https://github.com/Bekaboo/deadcolumn.nvim/issues/16)) ([c3eedd2](https://github.com/Bekaboo/deadcolumn.nvim/commit/c3eedd20209617910743f3e3e829082dbedb3356))
* **configs:** error when using 'visible' scope in empty buffer ([d06f166](https://github.com/Bekaboo/deadcolumn.nvim/commit/d06f166cb42e68a15e9c21230dea43f54531eb67))
* invalid alpha (&gt;1) when length > cc ([40a1ddd](https://github.com/Bekaboo/deadcolumn.nvim/commit/40a1ddda3f7adc5d0cc8d230ce8a9e94fc09ef91))
* **readme:** 'opts.scope' example config ([dc859ec](https://github.com/Bekaboo/deadcolumn.nvim/commit/dc859ecb1a39c5d842d26596e02393ab6c54899a))
* **readme:** indentation ([f6c4a2b](https://github.com/Bekaboo/deadcolumn.nvim/commit/f6c4a2b20b74417d2cbf7bc41b0342d5d882067d))


### Code Refactoring

* use `winhl` instead of setting `cc` directly ([ce15b17](https://github.com/Bekaboo/deadcolumn.nvim/commit/ce15b1750c3bb1f7d2bc26492491f8cdcd313ff5))
