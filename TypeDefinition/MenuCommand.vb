Imports System.ComponentModel
Public Class EditMenuItemCommand
    Implements System.Windows.Input.ICommand

    Public Event CanExecuteChanged As System.EventHandler Implements System.Windows.Input.ICommand.CanExecuteChanged

    Public Sub Execute(parameter As Object) Implements System.Windows.Input.ICommand.Execute
        parameter.ContextMenu.PlacementTarget = parameter
        parameter.ContextMenu.Placement = System.Windows.Controls.Primitives.PlacementMode.Top
        parameter.ContextMenu.IsOpen = True

        Dim Action As System.Action = Sub() RaiseEvent Click(parameter)
        Action()
    End Sub

    Public Function CanExecute(parameter As Object) As Boolean Implements System.Windows.Input.ICommand.CanExecute
        Return True
    End Function

    Public Event Click(parameter As Object)

End Class


Public Class RemoveItemCommand
    Implements System.Windows.Input.ICommand

    Public Event CanExecuteChanged As System.EventHandler Implements System.Windows.Input.ICommand.CanExecuteChanged

    Public Sub Execute(parameter As Object) Implements System.Windows.Input.ICommand.Execute
        Dim Action As System.Action = Sub() RaiseEvent Click()
        Action()
    End Sub

    Public Function CanExecute(parameter As Object) As Boolean Implements System.Windows.Input.ICommand.CanExecute
        Return True
    End Function

    Public Event Click()

End Class


Public Class OptionComponentCheckBoxCommand
    Implements System.Windows.Input.ICommand

    Public Event CanExecuteChanged As System.EventHandler Implements System.Windows.Input.ICommand.CanExecuteChanged

    Public Sub Execute(parameter As Object) Implements System.Windows.Input.ICommand.Execute
        If (parameter.IsEnabled And parameter.Tag = "WindowsFeature" And parameter.IsChecked) Then
            parameter.ContextMenu.PlacementTarget = parameter
            parameter.ContextMenu.Placement = System.Windows.Controls.Primitives.PlacementMode.Top
            parameter.ContextMenu.IsOpen = True
        End If

        Dim Action As System.Action = Sub() RaiseEvent Check(parameter)
        Action()
    End Sub

    Public Function CanExecute(parameter As Object) As Boolean Implements System.Windows.Input.ICommand.CanExecute
        Return True
    End Function

    Public Event Check(parameter As Object)

End Class


Public Class DetailsButtonCommand
    Implements System.Windows.Input.ICommand

    Public Event CanExecuteChanged As System.EventHandler Implements System.Windows.Input.ICommand.CanExecuteChanged

    Public Sub Execute(parameter As Object) Implements System.Windows.Input.ICommand.Execute
        Dim Action As System.Action = Sub() RaiseEvent Click(parameter)
        Action()
    End Sub

    Public Function CanExecute(parameter As Object) As Boolean Implements System.Windows.Input.ICommand.CanExecute
        Return True
    End Function

    Public Event Click(parameter As Object)

End Class

Public Class InverseIsCheckedCommand
    Implements System.Windows.Input.ICommand

    Public Event CanExecuteChanged As System.EventHandler Implements System.Windows.Input.ICommand.CanExecuteChanged

    Public Sub Execute(parameter As Object) Implements System.Windows.Input.ICommand.Execute
        parameter.IsChecked = Not parameter.IsChecked
        Dim Action As System.Action = Sub() RaiseEvent IsChecked(parameter)
        Action()
    End Sub

    Public Function CanExecute(parameter As Object) As Boolean Implements System.Windows.Input.ICommand.CanExecute
        Return parameter.IsEnabled
    End Function

    Public Event IsChecked(parameter As Object)

End Class


Public Class OptionComponentsItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Public Property OptionComponentCheckBox As OptionComponentCheckBoxCommand
    Public Property DetailsButton As DetailsButtonCommand
    Public Property InverseIsChecked As InverseIsCheckedCommand

    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Sub New()
        DetailsButton = New DetailsButtonCommand
        NotifyPropertyChanged("DetailsButton")
        OptionComponentCheckBox = New OptionComponentCheckBoxCommand
        NotifyPropertyChanged("OptionComponentCheckBox")
        InverseIsChecked = New InverseIsCheckedCommand
        NotifyPropertyChanged("InverseIsChecked")
    End Sub

    Dim _DisplayName As String = ""
    Public Property DisplayName As String
        Get
            Return _DisplayName
        End Get
        Set(value As String)
            _DisplayName = value
            NotifyPropertyChanged("DisplayName")
        End Set
    End Property
    Dim _Reason As String = ""
    Public Property Reason As String
        Get
            Return _Reason
        End Get
        Set(value As String)
            _Reason = value
            NotifyPropertyChanged("Reason")
        End Set
    End Property
    Dim _FileName As String = ""
    Public Property FileName As String
        Get
            Return _FileName
        End Get
        Set(value As String)
            _FileName = value
            NotifyPropertyChanged("FileName")
        End Set
    End Property
    Dim _AcceptEula As String = ""
    Public Property AcceptEula As String
        Get
            Return _AcceptEula
        End Get
        Set(value As String)
            _AcceptEula = value
            NotifyPropertyChanged("AcceptEula")
        End Set
    End Property
    Dim _DownloadUrl As String = ""
    Public Property DownloadUrl As String
        Get
            Return _DownloadUrl
        End Get
        Set(value As String)
            _DownloadUrl = value
            NotifyPropertyChanged("DownloadUrl")
        End Set
    End Property
    Dim _DetailsUrl As String = ""
    Public Property DetailsUrl As String
        Get
            Return _DetailsUrl
        End Get
        Set(value As String)
            _DetailsUrl = value
            NotifyPropertyChanged("DetailsUrl")
        End Set
    End Property
    Dim _SilentInstall As String = ""
    Public Property SilentInstall As String
        Get
            Return _SilentInstall
        End Get
        Set(value As String)
            _SilentInstall = value
            NotifyPropertyChanged("SilentInstall")
        End Set
    End Property
    Dim _CheckCurrentVersion As String = ""
    Public Property CheckCurrentVersion As String
        Get
            Return _CheckCurrentVersion
        End Get
        Set(value As String)
            _CheckCurrentVersion = value
            NotifyPropertyChanged("CheckCurrentVersion")
        End Set
    End Property
    Dim _PsModuleName As String = ""
    Public Property PsModuleName As String
        Get
            Return _PsModuleName
        End Get
        Set(value As String)
            _PsModuleName = value
            NotifyPropertyChanged("PsModuleName")
        End Set
    End Property
    Dim _WindowsFeatureName As String = ""
    Public Property WindowsFeatureName As String
        Get
            Return _WindowsFeatureName
        End Get
        Set(value As String)
            _WindowsFeatureName = value
            NotifyPropertyChanged("WindowsFeatureName")
        End Set
    End Property
    Dim _WindowsCapabilityName As String = ""
    Public Property WindowsCapabilityName As String
        Get
            Return _WindowsCapabilityName
        End Get
        Set(value As String)
            _WindowsCapabilityName = value
            NotifyPropertyChanged("WindowsCapabilityName")
        End Set
    End Property
    Dim _TargetOperatingSystemProductType As String = ""
    Public Property TargetOperatingSystemProductType As String
        Get
            Return _TargetOperatingSystemProductType
        End Get
        Set(value As String)
            _TargetOperatingSystemProductType = value
            NotifyPropertyChanged("TargetOperatingSystemProductType")
        End Set
    End Property
    Dim _RequiredConnectedToInternet As String = ""
    Public Property RequiredConnectedToInternet As String
        Get
            Return _RequiredConnectedToInternet
        End Get
        Set(value As String)
            _RequiredConnectedToInternet = value
            NotifyPropertyChanged("RequiredConnectedToInternet")
        End Set
    End Property
    Dim _Installed As Boolean = False
    Public Property Installed As Boolean
        Get
            Return _Installed
        End Get
        Set(value As Boolean)
            _Installed = value
            NotifyPropertyChanged("Installed")
        End Set
    End Property

    Dim _IsSelected As Boolean = False
    Public Property IsSelected As Boolean
        Get
            Return _IsSelected
        End Get
        Set(value As Boolean)
            _IsSelected = value
            NotifyPropertyChanged("IsSelected")
        End Set
    End Property
    Dim _IsEnabled As Boolean = False
    Public Property IsEnabled As Boolean
        Get
            Return _IsEnabled
        End Get
        Set(value As Boolean)
            _IsEnabled = value
            NotifyPropertyChanged("IsEnabled")
        End Set
    End Property
    Dim _Status As String = ""
    Public Property Status As String
        Get
            Return _Status
        End Get
        Set(value As String)
            _Status = value
            NotifyPropertyChanged("Status")
        End Set
    End Property

End Class


Public Class ApproveNeededUpdatesRuleItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Public Property EditMenuItem_Click As EditMenuItemCommand
    Public Property RemoveItemButton_Click As RemoveItemCommand

    Sub New()
        RemoveItemButton_Click = New RemoveItemCommand
        NotifyPropertyChanged("RemoveButtonItem_Click")
        EditMenuItem_Click = New EditMenuItemCommand
        NotifyPropertyChanged("EditMenuItem_Click")
    End Sub

    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Dim _FeatureUpdates As Boolean = False
    Public Property FeatureUpdates As Boolean
        Get
            Return _FeatureUpdates
        End Get
        Set(value As Boolean)
            _FeatureUpdates = value
            NotifyPropertyChanged("FeatureUpdates")
            NotifyPropertyChanged("ToStringWithoutTargetGroupName")
        End Set
    End Property
    Dim _QualityUpdates As Boolean = False
    Public Property QualityUpdates As Boolean
        Get
            Return _QualityUpdates
        End Get
        Set(value As Boolean)
            _QualityUpdates = value
            NotifyPropertyChanged("QualityUpdates")
            NotifyPropertyChanged("ToStringWithoutTargetGroupName")
        End Set
    End Property
    Dim _ApproveWaitDays As Integer = 0
    Public Property ApproveWaitDays As Integer
        Get
            Return _ApproveWaitDays
        End Get
        Set(value As Integer)
            _ApproveWaitDays = value
            NotifyPropertyChanged("ApproveWaitDays")
            NotifyPropertyChanged("ToStringWithoutTargetGroupName")
        End Set
    End Property
    Dim _TargetGroupName As String = ""
    Public Property TargetGroupName As String
        Get
            Return _TargetGroupName
        End Get
        Set(value As String)
            _TargetGroupName = value
            NotifyPropertyChanged("TargetGroupName")
            NotifyPropertyChanged("ToStringWithoutTargetGroupName")
        End Set
    End Property

    Public ReadOnly Property TargetGroupNameDisplayText As String
        Get
            If String.IsNullOrEmpty(TargetGroupName) Then
                Return "すべてのコンピューター"
            Else
                Return _TargetGroupName
            End If
        End Get
    End Property

    Public ReadOnly Property ToStringWithoutTargetGroupName As String
        Get
            Dim Text As String = ""
            If (ApproveWaitDays > 0) Then
                Text += String.Format("公開から {0} 日経過後に", ApproveWaitDays)
            Else
                Text += "実行時に"
            End If
            If (FeatureUpdates And QualityUpdates) Then
                Text += "すべての更新プログラムを承認する"
            ElseIf FeatureUpdates Then
                Text += "機能更新プログラムのみ承認する"
            ElseIf QualityUpdates Then
                Text += "品質更新プログラムのみ承認する"
            Else
                Text = "実行しない"
            End If

            Return Text
        End Get
    End Property

End Class
