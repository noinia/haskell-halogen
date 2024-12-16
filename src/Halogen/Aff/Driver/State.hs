module Halogen.Aff.Driver.State
  ( LifecycleHandlers(..)
  , DriverState(..)
  , DriverStateRef(..)
  , DriverStateX (..)
  -- , unDriverStateX
  -- , mkDriverStateXRef
  , RenderStateX (..)
  -- , renderStateX
  -- , renderStateX_
  -- , unRenderStateX
  , initDriverState
  ) where

import Protolude
import Halogen.Data.Slot as SlotStorage
import Data.Primitive
import Control.Monad.Primitive
import Web.DOM.Element (Element)
import Halogen.Component
import Halogen.Query.HalogenM
import qualified Halogen.Subscription as HS

data LifecycleHandlers m = LifecycleHandlers
  { initializers :: [m ()]
  , finalizers :: [m ()]
  }

data DriverState m r s f act ps i o = DriverState
  { component :: ComponentSpec s f act ps i o m
  , state :: s
  , refs :: Map Text Element
  , children :: SlotStorage ps (DriverStateRef m r)
  , childrenIn :: MutVar (PrimState m) (SlotStorage ps (DriverStateRef m r))
  , childrenOut :: MutVar (PrimState m) (SlotStorage ps (DriverStateRef m r))
  , selfRef :: MutVar (PrimState m) (DriverState m r s f act ps i o)
  , handlerRef :: MutVar (PrimState m) (o -> m ())
  , pendingQueries :: MutVar (PrimState m) (Maybe [m ()])
  , pendingOuts :: MutVar (PrimState m) (Maybe [m ()])
  , pendingHandlers :: MutVar (PrimState m) (Maybe [m ()])
  , rendering :: Maybe (r s act ps o)
  , fresh :: MutVar (PrimState m) Int
  , subscriptions :: MutVar (PrimState m) (Maybe (Map SubscriptionId (HS.Subscription m)))
  , forks :: MutVar (PrimState m) (Map ForkId (Async ()))
  , lifecycleHandlers :: MutVar (PrimState m) (LifecycleHandlers m)
  }

data DriverStateX m r f o = forall s act ps i. DriverStateX (DriverState m r s f act ps i o)
data DriverStateRef m r f o = forall s act ps i. DriverStateRef (MutVar (PrimState m) (DriverState m r s f act ps i o))

data RenderStateX r = forall s act ps o. RenderStateX (r s act ps o)


initDriverState
  :: PrimMonad m
  => ComponentSpec s f act ps i o m
  -> i
  -> (o -> m ())
  -> MutVar (PrimState m) (LifecycleHandlers m)
  -> m (DriverStateRef m r f o)
initDriverState component input handler lchs = do
  selfRef <- newMutVar (fix identity)
  childrenIn <- newMutVar SlotStorage.empty
  childrenOut <- newMutVar SlotStorage.empty
  handlerRef <- newMutVar handler
  pendingQueries <- newMutVar (Just [])
  pendingOuts <- newMutVar (Just [])
  pendingHandlers <- newMutVar Nothing
  fresh <- newMutVar 1
  subscriptions <- newMutVar (Just mempty)
  forks <- newMutVar mempty
  let
    ds = DriverState
      { component
      , state = component.initialState input
      , refs = mempty
      , children = SlotStorage.empty
      , childrenIn
      , childrenOut
      , selfRef
      , handlerRef
      , pendingQueries
      , pendingOuts
      , pendingHandlers
      , rendering = Nothing
      , fresh
      , subscriptions
      , forks
      , lifecycleHandlers = lchs
      }
  writeMutVar selfRef ds
  pure $ DriverStateRef selfRef
