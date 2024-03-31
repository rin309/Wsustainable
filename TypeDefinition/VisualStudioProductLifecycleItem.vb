Imports System.ComponentModel

Public Class VisualStudioLifecycleItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Public Event SelectionChanged(sender As VisualStudioLifecycleItem, e As SelectionChangedEventArgs)

    Class SelectionChangedEventArgs
        Inherits System.EventArgs

        Sub New(Trigger As Reason)
            Me.Trigger = Trigger
        End Sub

        Enum Reason
            Selected
            DeclineOldVersions
        End Enum

        Public Property Trigger As Reason

    End Class

    Sub New()
        _Selected = False
        _DeclineOldVersions = false

        _Enabled = True
    End Sub

    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Public NeededProducts As String
    Public IsPro, IsEnterpriseWithoutLtsc, IsLtsc As Boolean

    Dim _Title, _Version, _EndDate As String
    Dim _Selected, _DeclineOldVersions As System.Nullable(Of Boolean)
    Dim _Enabled As Boolean


    Public Property Title As String
        Get
            Return _Title
        End Get
        Set(value As String)
            _Title = value
            NotifyPropertyChanged("Title")
        End Set
    End Property

    Public Property Version As String
        Get
            Return _Version
        End Get
        Set(value As String)
            _Version = value
            NotifyPropertyChanged("Version")
        End Set
    End Property

    Public Property EndDate As String
        Get
            Return _EndDate
        End Get
        Set(value As String)
            _EndDate = value
            NotifyPropertyChanged("EndDate")
        End Set
    End Property

    Public Property Selected As System.Nullable(Of Boolean)
        Get
            Return _Selected
        End Get
        Set(value As System.Nullable(Of Boolean))
            _Selected = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs(SelectionChangedEventArgs.Reason.Selected))
            NotifyPropertyChanged("Selected")
        End Set
    End Property
    Public Property DeclineOldVersions As System.Nullable(Of Boolean)
        Get
            Return _DeclineOldVersions
        End Get
        Set(value As System.Nullable(Of Boolean))
            _DeclineOldVersions = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs(SelectionChangedEventArgs.Reason.DeclineOldVersions))
            NotifyPropertyChanged("DeclineOldVersions")
        End Set
    End Property

    Public Property Enabled As Boolean
        Get
            Return _Enabled
        End Get
        Set(value As Boolean)
            _Enabled = value
            NotifyPropertyChanged("Enabled")
        End Set
    End Property

    Public SelectionChangedCancelRequest As Boolean = False

End Class
