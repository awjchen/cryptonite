{-# LANGUAGE ForeignFunctionInterface, CPP, MultiParamTypeClasses #-}

-- |
-- Module      : Crypto.Hash.Internal.%%MODULENAME%%
-- License     : BSD-style
-- Maintainer  : Vincent Hanquez <vincent@snarc.org>
-- Stability   : experimental
-- Portability : unknown
--
-- A module containing %%MODULENAME%% bindings
--
module Crypto.Hash.Internal.%%MODULENAME%%
    ( Ctx(..)
    -- * Internal values
    , digestSize
    , sizeCtx
    -- * Internal IO hash functions
    , internalInit
    , internalInitAt
    , internalUpdate
    , internalUpdateUnsafe
    , internalFinalize
    -- * Context copy and creation
    , withCtxCopy
    , withCtxNewThrow
    , withCtxThrow
    ) where

import Foreign.Ptr
import Data.ByteString (ByteString)
import Data.ByteString.Unsafe (unsafeUseAsCStringLen)
import Data.ByteString.Internal (create)
import Data.Word
import Crypto.Internal.Memory

newtype Ctx = Ctx Bytes

{-# INLINE digestSize #-}
digestSize :: Int
digestSize = %%DIGESTSIZE%%

{-# INLINE sizeCtx #-}
sizeCtx :: Int
sizeCtx = %%SIZECTX%%

withCtxCopy :: Ctx -> (Ptr Ctx -> IO ()) -> IO Ctx
withCtxCopy (Ctx b) f = Ctx `fmap` bytesCopyAndModify b f

withCtxThrow :: Ctx -> (Ptr Ctx -> IO a) -> IO a
withCtxThrow (Ctx b) f = bytesCopyTemporary b f

withCtxNewThrow :: (Ptr Ctx -> IO a) -> IO a
withCtxNewThrow f = bytesTemporary %%SIZECTX%% f

foreign import ccall unsafe "cryptonite_%%HEADER_FILE%% cryptonite_%%HASHNAME%%_init"
    c_%%HASHNAME%%_init :: Ptr Ctx -> IO ()

foreign import ccall "cryptonite_%%HEADER_FILE%% cryptonite_%%HASHNAME%%_update"
    c_%%HASHNAME%%_update :: Ptr Ctx -> Ptr Word8 -> Word32 -> IO ()

foreign import ccall unsafe "cryptonite_%%HEADER_FILE%% cryptonite_%%HASHNAME%%_update"
    c_%%HASHNAME%%_update_unsafe :: Ptr Ctx -> Ptr Word8 -> Word32 -> IO ()

foreign import ccall unsafe "cryptonite_%%HEADER_FILE%% cryptonite_%%HASHNAME%%_finalize"
    c_%%HASHNAME%%_finalize :: Ptr Ctx -> Ptr Word8 -> IO ()

internalInitAt :: Ptr Ctx -> IO ()
internalInitAt = c_%%HASHNAME%%_init

-- | init a context
internalInit :: IO Ctx
internalInit = Ctx `fmap` bytesAlloc %%SIZECTX%% internalInitAt

-- | Update a context in place
internalUpdate :: Ptr Ctx -> ByteString -> IO ()
internalUpdate ptr d =
    unsafeUseAsCStringLen d (\(cs, len) -> c_%%HASHNAME%%_update ptr (castPtr cs) (fromIntegral len))

-- | Update a context in place using an unsafe foreign function call.
--
-- It is faster than `internalUpdate`, but will block the haskell runtime.
-- This shouldn't be used if the input data is large.
internalUpdateUnsafe :: Ptr Ctx -> ByteString -> IO ()
internalUpdateUnsafe ptr d =
    unsafeUseAsCStringLen d (\(cs, len) -> c_%%HASHNAME%%_update_unsafe ptr (castPtr cs) (fromIntegral len))

-- | Finalize a context in place
internalFinalize :: Ptr Ctx -> IO ByteString
internalFinalize ptr = create digestSize (c_%%HASHNAME%%_finalize ptr)
