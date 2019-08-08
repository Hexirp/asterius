{-# LANGUAGE MagicHash #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE StrictData #-}
{-# LANGUAGE UnboxedTuples #-}
{-# LANGUAGE UnliftedFFITypes #-}

module Asterius.Types
  ( JSVal(..)
  , JSArrayBuffer(..)
  , JSString(..)
  , JSArray(..)
  , JSObject(..)
  , JSFunction(..)
  , JSException(..)
  , fromJSArrayBuffer
  , toJSArrayBuffer
  , fromJSString
  , toJSString
  , fromJSArray
  , toJSArray
  , indexJSObject
  , setJSObject
  , jsonParse
  , jsonStringify
  , callJSFunction
  , makeHaskellCallback
  , makeHaskellCallback1
  , makeHaskellCallback2
  , makeJSException
  , jsStringDecodeUTF8
  , jsStringEncodeUTF8
  , jsStringDecodeLatin1
  , jsStringEncodeLatin1
  , jsStringDecodeUTF16LE
  , jsStringEncodeUTF16LE
  , jsStringDecodeUTF32LE
  , jsStringEncodeUTF32LE
  , js_freezeTmpJSVal
  ) where

import Asterius.Magic
import GHC.Exception.Type
import GHC.Magic
import GHC.Prim
import GHC.Show
import GHC.Stable
import GHC.Tuple
import GHC.Types

newtype JSVal =
  JSVal (StablePtr ())

newtype JSArrayBuffer =
  JSArrayBuffer JSVal

newtype JSString =
  JSString JSVal

newtype JSArray =
  JSArray JSVal

newtype JSObject =
  JSObject JSVal

newtype JSFunction =
  JSFunction JSVal

data JSException =
  JSException JSVal
              [Char]

instance Show JSException where
  show (JSException _ msg) = msg

instance Exception JSException

{-# INLINE fromJSArrayBuffer #-}
fromJSArrayBuffer :: JSArrayBuffer -> ByteArray#
fromJSArrayBuffer buf = accursedUnutterableAddrToAny (c_fromJSArrayBuffer buf)

{-# INLINE toJSArrayBuffer #-}
toJSArrayBuffer :: Addr# -> Int -> JSArrayBuffer
toJSArrayBuffer = c_toJSArrayBuffer

{-# INLINE indexJSObject #-}
indexJSObject :: JSObject -> [Char] -> IO JSVal
indexJSObject obj k = js_object_index obj (toJSString k)

{-# INLINE setJSObject #-}
setJSObject :: JSObject -> [Char] -> JSVal -> IO ()
setJSObject obj k = js_object_set obj (toJSString k)

{-# INLINE jsonParse #-}
jsonParse :: [Char] -> JSVal
jsonParse s = js_jsonParse (toJSString s)

{-# INLINE jsonStringify #-}
jsonStringify :: JSVal -> [Char]
jsonStringify v = fromJSString (js_jsonStringify v)

{-# INLINE callJSFunction #-}
callJSFunction :: JSFunction -> [JSVal] -> IO JSVal
callJSFunction f args = js_apply f (toJSArray args)

{-# INLINE makeHaskellCallback #-}
makeHaskellCallback :: IO () -> IO JSFunction
makeHaskellCallback f =
  IO
    (\s0 ->
       case makeStablePtr# f s0 of
         (# s1, sp #) -> unIO (js_mk_hs_callback sp) s1)

{-# INLINE makeHaskellCallback1 #-}
makeHaskellCallback1 :: (JSVal -> IO ()) -> IO JSFunction
makeHaskellCallback1 f =
  IO
    (\s0 ->
       case makeStablePtr# f s0 of
         (# s1, sp #) -> unIO (js_mk_hs_callback1 sp) s1)

{-# INLINE makeHaskellCallback2 #-}
makeHaskellCallback2 :: (JSVal -> JSVal -> IO ()) -> IO JSFunction
makeHaskellCallback2 f =
  IO
    (\s0 ->
       case makeStablePtr# f s0 of
         (# s1, sp #) -> unIO (js_mk_hs_callback2 sp) s1)

{-# INLINE makeJSException #-}
makeJSException :: JSVal -> SomeException
makeJSException v = toException (JSException v (fromJSString (js_err_toString v)))

{-# INLINE fromJSString #-}
fromJSString :: JSString -> [Char]
fromJSString s = accursedUnutterableAddrToAny (c_fromJSString s)

{-# INLINE toJSString #-}
toJSString :: [Char] -> JSString
toJSString s =
  runRW#
    (\s0 ->
       case unIO js_newString s0 of
         (# s1, i #) ->
           let w [] sx = (# sx, () #)
               w (c:cs) sx =
                 case unIO (js_appendString i c) sx of
                   (# sy, _ #) -> w cs sy
            in case w s s1 of
                 (# s2, _ #) ->
                   case unIO (js_freezeTmpJSVal i) s2 of
                     (# _, r #) -> JSString r)

{-# INLINE fromJSArray #-}
fromJSArray :: JSArray -> [JSVal]
fromJSArray arr = accursedUnutterableAddrToAny (c_fromJSArray arr)

{-# INLINE toJSArray #-}
toJSArray :: [JSVal] -> JSArray
toJSArray arr =
  runRW#
    (\s0 ->
       case unIO js_newArray s0 of
         (# s1, i #) ->
           let w [] sx = (# sx, () #)
               w (v:vs) sx =
                 case unIO (js_appendArray i v) sx of
                   (# sy, _ #) -> w vs sy
            in case w arr s1 of
                 (# s2, _ #) ->
                   case unIO (js_freezeTmpJSVal i) s2 of
                     (# _, r #) -> JSArray r)

foreign import ccall unsafe "__asterius_fromJSArrayBuffer" c_fromJSArrayBuffer
  :: JSArrayBuffer -> Addr#

foreign import ccall unsafe "__asterius_toJSArrayBuffer" c_toJSArrayBuffer
  :: Addr# -> Int -> JSArrayBuffer

foreign import ccall unsafe "__asterius_fromJSString" c_fromJSString
  :: JSString -> Addr#

foreign import ccall unsafe "__asterius_fromJSArray" c_fromJSArray
  :: JSArray -> Addr#

foreign import javascript "__asterius_jsffi.newTmpJSVal('')" js_newString
  :: IO Int

foreign import javascript "__asterius_jsffi.mutTmpJSVal(${1}, s => s + String.fromCodePoint(${2}))" js_appendString
  :: Int -> Char -> IO ()

foreign import javascript "__asterius_jsffi.newTmpJSVal([])" js_newArray
  :: IO Int

foreign import javascript "__asterius_jsffi.mutTmpJSVal(${1}, arr => (arr.push(${2}), arr))" js_appendArray
  :: Int -> JSVal -> IO ()

foreign import javascript "__asterius_jsffi.freezeTmpJSVal(${1})" js_freezeTmpJSVal
  :: Int -> IO JSVal

foreign import javascript "__asterius_jsffi.decodeUTF8(${1})" jsStringDecodeUTF8
  :: JSArrayBuffer -> JSString

foreign import javascript "__asterius_jsffi.encodeUTF8(${1})" jsStringEncodeUTF8
  :: JSString -> JSArrayBuffer

foreign import javascript "__asterius_jsffi.decodeLatin1(${1})" jsStringDecodeLatin1
  :: JSArrayBuffer -> JSString

foreign import javascript "__asterius_jsffi.encodeLatin1(${1})" jsStringEncodeLatin1
  :: JSString -> JSArrayBuffer

foreign import javascript "__asterius_jsffi.decodeUTF16LE(${1})" jsStringDecodeUTF16LE
  :: JSArrayBuffer -> JSString

foreign import javascript "__asterius_jsffi.encodeUTF16LE(${1})" jsStringEncodeUTF16LE
  :: JSString -> JSArrayBuffer

foreign import javascript "__asterius_jsffi.decodeUTF32LE(${1})" jsStringDecodeUTF32LE
  :: JSArrayBuffer -> JSString

foreign import javascript "__asterius_jsffi.encodeUTF32LE(${1})" jsStringEncodeUTF32LE
  :: JSString -> JSArrayBuffer

foreign import javascript "${1}[${2}]" js_object_index
  :: JSObject -> JSString -> IO JSVal

foreign import javascript "${1}[${2}]=${3}" js_object_set
  :: JSObject -> JSString -> JSVal -> IO ()

foreign import javascript "${1}.apply({},${2})" js_apply
  :: JSFunction -> JSArray -> IO JSVal

foreign import javascript "__asterius_jsffi.makeHaskellCallback(${1})" js_mk_hs_callback
  :: StablePtr# (IO ()) -> IO JSFunction

foreign import javascript "__asterius_jsffi.makeHaskellCallback1(${1})" js_mk_hs_callback1
  :: StablePtr# (JSVal -> IO ()) -> IO JSFunction

foreign import javascript "__asterius_jsffi.makeHaskellCallback2(${1})" js_mk_hs_callback2
  :: StablePtr# (JSVal -> JSVal -> IO ()) -> IO JSFunction

foreign import javascript "JSON.parse(${1})" js_jsonParse :: JSString -> JSVal

foreign import javascript "JSON.stringify(${1})" js_jsonStringify
  :: JSVal -> JSString

foreign import javascript "${1}.stack ? ${1}.stack : ${1}.toString()" js_err_toString
  :: JSVal -> JSString
