module Arkham.Types.Investigator.Cards.WendyAdams
  ( WendyAdams(..)
  , wendyAdams
  ) where

import Arkham.Prelude

import Arkham.Investigator.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.AssetId
import Arkham.Types.Card
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Game.Helpers
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Matcher
import Arkham.Types.Message hiding (RevealToken)
import Arkham.Types.Source
import Arkham.Types.Timing qualified as Timing
import Arkham.Types.Window (Window(..))
import Arkham.Types.Window qualified as Window

newtype WendyAdams = WendyAdams InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

wendyAdams :: InvestigatorCard WendyAdams
wendyAdams = investigator
  WendyAdams
  Cards.wendyAdams
  Stats
    { health = 7
    , sanity = 7
    , willpower = 4
    , intellect = 3
    , combat = 1
    , agility = 4
    }

instance HasTokenValue env WendyAdams where
  getTokenValue (WendyAdams attrs) iid ElderSign | iid == investigatorId attrs =
    pure $ TokenValue ElderSign (PositiveModifier 0)
  getTokenValue _ _ token = pure $ TokenValue token mempty

instance HasAbilities WendyAdams where
  getAbilities (WendyAdams attrs) =
    [ restrictedAbility
          attrs
          1
          Self
          (ReactionAbility (RevealChaosToken Timing.When You AnyToken)
          $ HandDiscardCost 1 Nothing mempty mempty
          )
        & (abilityLimitL .~ PlayerLimit PerTestOrAbility 1)
    ]

instance (InvestigatorRunner env) => RunMessage env WendyAdams where
  runMessage msg i@(WendyAdams attrs@InvestigatorAttrs {..}) = case msg of
    UseCardAbility _ (InvestigatorSource iid) [Window _ (Window.RevealToken _ token)] 1 _
      | iid == investigatorId
      -> do
        cancelToken token
        i <$ pushAll
          [ CancelNext RunWindowMessage
          , CancelNext DrawTokenMessage
          , CancelNext RevealTokenMessage
          , ReturnTokens [token]
          , UnfocusTokens
          , DrawAnotherToken iid
          ]
    -- When (DrawToken iid token) | iid == investigatorId -> i <$ pushAll
    --   [ FocusTokens [token]
    --   , CheckWindow
    --     investigatorId
    --     [Window Timing.When (Window.DrawToken investigatorId token)]
    --   , UnfocusTokens
    --   ]
    ResolveToken _drawnToken ElderSign iid | iid == investigatorId -> do
      maid <- getId @(Maybe AssetId) (CardCode "01014")
      i <$ when (isJust maid) (push PassSkillTest)
    _ -> WendyAdams <$> runMessage msg attrs
