module Main where

  import Prelude

  import Numeric.YHSeq.V0201 as V0201 ( expandList )

  import Asterius.Types ( JSString, fromJSString, toJSString )

  expandStringV0201 :: String -> Int -> String
  expandStringV0201 x n = case V0201.expandList (read x) n of
    Left e -> show e
    Right x' -> show x'

  expandJSStringV0201 :: JSString -> Int -> JSString
  expandJSStringV0201 x n = toJSString (expandString (fromJSString x) n)

  foreign export javascript "expandJSStringV0201" expandJSStringV0201 :: JSString -> Int -> JSString
