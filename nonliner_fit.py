import numpy as np
from sklearn.model_selection import LeaveOneOut
import pandas as pd
from scipy.optimize import curve_fit
import heapq
from math import sqrt
import matplotlib.pyplot as plt
from numpy import array
import seaborn as sns
from sklearn.linear_model import LinearRegression

data = pd.read_excel(r'C:\Users\dell\Desktop\Revised\LOOCV_AH.xlsx',sheet_name='20170329')
data_x = data['NDVI']
data_y = data['LAI']
NDVI = data_x.values
# print(NDVI)
LAI = data_y.values
#print(NDVI_test)

loo = LeaveOneOut()
loo.get_n_splits(NDVI)
print('交叉验证次数:',loo.get_n_splits(NDVI))

def func(x,a,b,k):
    C = np.log((b - a) / (b - x))
    y_pred = np.multiply(C,k)
    return y_pred
LAI_test_pred=[]
NDVI_test=[]
LAI_test = []
LAI_ALL_P = []
param=[]
A=[]
B=[]
K=[]
for train_index, test_index in loo.split(NDVI):
    X_train, X_test = NDVI[train_index],NDVI[test_index]
    y_train, y_test = LAI[train_index],LAI[test_index]

    param_bounds = ([0.01,0.93,1.3],[0.15,0.95,1.8]) #参数上下限，第一个方括号为所有参数下限，第二个为所有参数上限
    popt, pcov = curve_fit(func,X_train,y_train,bounds=param_bounds)
    param.append(popt)
    a = popt[0]
    b = popt[1]
    k = popt[2]
    A.append(a)
    B.append(b)
    K.append(k)
    NDVI_test.append(X_test)
    LAI_test.append(y_test)
    LAI_all_pred = func(NDVI,a,b,k)
    LAI_pred = func(NDVI_test,a,b,k)
    LAI_test_pred.append(LAI_pred)

    LAI_ALL_P.append(LAI_all_pred)


A = np.array(A)
B = np.array(B)
K = np.array(K)
param = np.array(param)
LAI_ALL_P = np.array(LAI_ALL_P)
NDVI_test=np.array(NDVI_test)
LAI_test=np.array(LAI_test)
LAI_test_pred=np.array(LAI_test_pred[len(LAI)-1])
e = array(LAI_test) #多个数组合并成一个数组
LAI_test = e.flatten()
f = array(LAI_test_pred)
LAI_test_pred = f.flatten()

error = []
for i in range(len(LAI)):
    error.append(LAI_ALL_P[i] - LAI)
error = np.array(error)

squaredError = []
absError = []
for val in error:
    squaredError.append(val * val)  # 差平方
    absError.append(abs(val))  # 误差绝对值
squaredError = np.array(squaredError)
absError = np.array(absError)
# print("Square Error: ", squaredError)
# print("Absolute Value of Error: ", absError)

RMSE = []
#RRMSE = []
for c in range(len(LAI)):
    rmse = sqrt(sum(squaredError[c]) / len(LAI))
    #rmse = sqrt((squaredError[c]) / LAI_test[c])
    RMSE.append(rmse)
    #rrmse = (sqrt(sum(squaredError[c]) / len(LAI))) / (np.mean(LAI))
    #RRMSE.append(rrmse)
RMSE = np.array(RMSE)

lreg = LinearRegression()
lreg.fit(LAI_test.reshape(-1, 1), LAI_test_pred.reshape(-1, 1))
y_prd = lreg.predict(LAI_test.reshape(-1, 1))
Regression = sum((y_prd - np.mean(LAI_test_pred))**2) #回归
Residual = sum(((LAI_test_pred.reshape(-1, 1))-y_prd)**2) #残差
R_square = Regression / (Regression + Residual) #相关系数R^2
print('R_square ='+ str('%.2f' % R_square))

for l in range(len(LAI)):
    if RMSE[l]==heapq.nsmallest(1,RMSE): #取RMSE最小对应的元素位置，从而得到对于的公式参数
         print(l)
         print('NDVI-LAI公式为:'+'LAI'+'='+str('%.2f' % K[l])+'*'+'ln'+'('+str('%.4f' % (B[l]-A[l]))+'/'\
               +'('+str('%.2f' % B[l])+'-'+'NDVI'+')' +')')
         print('RMSE='+str('%.2f' % RMSE[l]))


sns.regplot(x=LAI_test, y=LAI_test_pred, marker="o",ci=None,color='b')
#plt.plot([LAI_field.min(), LAI_field.max()], [LAI_pred.min(), LAI_pred.max()], 'r--', lw=2, label = '拟合线')
plt.xlim(0, 8)
plt.ylim(0, 8)
plt.plot([0,max(plt.xlim())],[0,max(plt.ylim())])

# sns.set(style='ticks',color_codes = True, font_scale=1.5, font='Times New Roman')
# font1 = {'family': 'Times New Roman',
#               'color': 'black',
#               'weight': 'normal',
#               'size': 20,
#               }
#
# sns.kdeplot(LAI_test,LAI_test_pred,cmap='Blues',shade=True,shade_lowest=False)
#
# # 设置坐标轴格式
# plt.tick_params(axis='both', which='major', labelsize=20)
# plt.xlabel('Field measured LAI', fontdict=font1)
# plt.ylabel('Fine resolution LAI', fontdict=font1)
# x_major_locator = MultipleLocator(1)
# y_major_locator = MultipleLocator(1)
# ax = plt.gca()
# ax.xaxis.set_major_locator(x_major_locator)
# ax.yaxis.set_major_locator(y_major_locator)
# labels = ax.get_xticklabels() + ax.get_yticklabels()
# [label.set_fontname('Times New Roman') for label in labels]
# plt.xlim(0, 6)
# plt.ylim(0, 6)
#
# plt.plot([0, max(plt.xlim())], [0, max(plt.ylim())])
# # text=plt.gca().get_legend().get_texts()[0].get_text()
# plt.legend(title='(a) 2004/4/1\n', loc=2, frameon=False, title_fontsize=22)
#
# # ax1=sns.kdeplot(LAI_test,LAI_test_pred,cmap='Blues',shade=True,shade_lowest=False)
# # ax2=sns.regplot(LAI_test,LAI_test_pred,color='w',marker='+',ci=None)
#plt.show()







