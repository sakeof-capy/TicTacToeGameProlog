using System;
using App.Logic_Components;
using UnityEngine;
using UnityEngine.UI;

namespace World.UI.Board.CellKinds
{
    public class StandardCell : MonoBehaviour, IRenderableCell
    {
        public event ICell.CellOperation OnInteraction;

        private CellValue _value;
        private CellState _state;

        [SerializeField] private Image _backImage;
        [SerializeField] private Image _shapeImage;

        [SerializeField] private Sprite EMPTY_SHAPE;
        [SerializeField] private Sprite CROSS_SHAPE;
        [SerializeField] private Sprite NAUGHT_SHAPE;

        [SerializeField] private Sprite DEFAULT_BACKGROUND;
        [SerializeField] private Sprite LOSS_BACKGROUND;
        [SerializeField] private Sprite WIN_BACKGROUND;

        #region IRenderableCell
        public CellValue Value 
        {
            get => _value;
            set
            {
                _value = value;
                SetCellValueShape(value);
            }
        }

        public CellState RenderedState 
        {
            get => _state; 
            set
            {
                _state = value;
                SetBackground(value);
            }
        }

        public GameObject GameObject => gameObject;

        private void SetBackground(CellState state)
        {
            _backImage.sprite = state switch
            {
                CellState.DEFAULT => DEFAULT_BACKGROUND,
                CellState.WIN_STATE => WIN_BACKGROUND,
                CellState.LOSS_STATE => LOSS_BACKGROUND,
                _ => throw new InvalidProgramException
                     ("The switch statement does not process all states."),
            };
        }

        private void SetCellValueShape(CellValue value)
        {
            _shapeImage.sprite = value switch
            {
                CellValue.EMPTY => EMPTY_SHAPE,
                CellValue.CROSS => CROSS_SHAPE,
                CellValue.NAUGHT => NAUGHT_SHAPE,
                _ => throw new InvalidProgramException
                     ("The switch statement does not process all states."),
            };
        }
        #endregion

        #region Mono Behaviour
        public void Awake()
        {
            Value = CellValue.EMPTY;
            RenderedState = CellState.DEFAULT;
            var shapeGameObject = _shapeImage.gameObject;
        }

        #endregion

        public void OnInteracted() => OnInteraction?.Invoke(this);
    }
}
