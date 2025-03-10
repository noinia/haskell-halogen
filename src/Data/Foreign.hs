{-# LANGUAGE CPP #-}
{-# LANGUAGE MagicHash #-}

module Data.Foreign where

-- #if !defined(javascript_HOST_ARCH)
import GHC.Base (isTrue#, reallyUnsafePtrEquality, reallyUnsafePtrEquality#)
-- #endif

import HPrelude
import Unsafe.Coerce (unsafeCoerce)

#if defined(javascript_HOST_ARCH)
import GHC.Base (Int#)
import GHC.JS.Prim

type Foreign tag = JSVal

newtype Nullable tag = Nullable (Foreign tag)

foreign import javascript unsafe "(($1) => { return (!!$1 ? 1 : 0); })" foreignToBool' :: Foreign tag -> Int#

nullableToMaybe :: Nullable tag -> Maybe (Foreign tag)
nullableToMaybe (Nullable o) = if isNull o || isUndefined o then Nothing else Just o

toForeign :: a -> Foreign tag
toForeign = unsafeCoerce

unsafeFromForeign :: Foreign tag -> a
unsafeFromForeign = unsafeCoerce

readProp :: Text -> (Foreign tag -> Maybe a) -> Foreign tag' -> Maybe a
readProp key f o = nullableToMaybe (Nullable $ unsafeGetProp o (toS key)) >>= f

-- TODO this doesn't work for some reason
--foreign import javascript unsafe "js_unsafe_ref_eq" js_unsafe_ref_eq :: JSVal -> JSVal -> Bool

--unsafeRefEq' :: a -> b -> Bool
--unsafeRefEq' a b = js_unsafe_ref_eq (unsafeCoerce a) (unsafeCoerce b)

--unsafeRefEq :: a -> a -> Bool
--unsafeRefEq a b = unsafeRefEq' a b

foreignToString :: Foreign tag -> Text
foreignToString = toS . fromJSString

foreignToInt :: Foreign tag -> Int
foreignToInt = fromJSInt

foreignToBool :: Foreign tag -> Bool
foreignToBool x = isTrue# (foreignToBool' x)
#else

newtype Foreign tag = Foreign Any

type Nullable tag = Maybe (Foreign tag)

nullableToMaybe :: Nullable tag -> Maybe (Foreign tag)
nullableToMaybe = identity

toForeign :: a -> Foreign tag
toForeign = Foreign . unsafeCoerce

unsafeFromForeign :: Foreign tag -> a
unsafeFromForeign (Foreign o) = unsafeCoerce o

readProp :: Text -> (Foreign tag -> Maybe a) -> Foreign tag' -> Maybe a
readProp = panic "Unavailable in GHC" -- TODO

foreignToString :: Foreign tag -> Text
foreignToString = unsafeCoerce

foreignToInt :: Foreign tag -> Int
foreignToInt = unsafeCoerce

foreignToBool :: Foreign tag -> Bool
foreignToBool = unsafeFromForeign
#endif

unsafeRefEq :: a -> a -> Bool
unsafeRefEq p q = isTrue# (reallyUnsafePtrEquality p q)

unsafeRefEq' :: a -> b -> Bool
unsafeRefEq' p q = isTrue# (reallyUnsafePtrEquality# p q)
