from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV
from config import PARAM_GRID, CV_FOLDS, MAX_ITER

def tune_lr(X_train, y_train):
    model = LogisticRegression(max_iter=MAX_ITER)

    grid = GridSearchCV(
        model,
        PARAM_GRID,
        cv=CV_FOLDS,
        scoring="accuracy",
        n_jobs=-1
    )
    grid.fit(X_train, y_train)

    print("LR Best Params:", grid.best_params_)
    return grid.best_estimator_
