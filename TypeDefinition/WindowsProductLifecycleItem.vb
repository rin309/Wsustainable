Imports System.ComponentModel

Public Class WindowsProductLifecycleItem
    Implements INotifyPropertyChanged
    Public Event PropertyChanged(sender As Object, e As PropertyChangedEventArgs) Implements INotifyPropertyChanged.PropertyChanged
    Public Event SelectionChanged(sender As WindowsProductLifecycleItem, e As SelectionChangedEventArgs)

    Class SelectionChangedEventArgs
        Inherits System.EventArgs

        Sub New(Trigger As Reason)
            Me.Trigger = Trigger
        End Sub

        Enum Reason
            Selected
            SelectedX86
            SelectedX64
            SelectedArm64
        End Enum

        Public Property Trigger As Reason

    End Class

    Sub New()
        _Selected = False
        _SelectedX86 = False
        _SelectedX64 = False
        _SelectedArm64 = False

        _Enabled = True
        _EnabledX86 = True
        _EnabledX64 = True
        _EnabledArm64 = True
    End Sub

    Private Sub NotifyPropertyChanged(Optional propertyName As String = "")
        RaiseEvent PropertyChanged(Me, New PropertyChangedEventArgs(propertyName))
    End Sub

    Public NeededProducts As String
    Public IsPro, IsEnterpriseWithoutLtsc, IsLtsc As Boolean

    Dim _Title, _Version, _EndDate As String
    Dim _Selected, _SelectedX86, _SelectedX64, _SelectedArm64 As System.Nullable(Of Boolean)
    Dim _VisibleX86, _VisibleX64, _VisibleArm64, _Enabled, _EnabledX86, _EnabledX64, _EnabledArm64 As Boolean


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

    Public Property VisibleX86 As Boolean
        Get
            Return _VisibleX86
        End Get
        Set(value As Boolean)
            _VisibleX86 = value
            NotifyPropertyChanged("VisibleX86")
        End Set
    End Property
    Public Property VisibleX64 As Boolean
        Get
            Return _VisibleX64
        End Get
        Set(value As Boolean)
            _VisibleX64 = value
            NotifyPropertyChanged("VisibleX64")
        End Set
    End Property
    Public Property VisibleArm64 As Boolean
        Get
            Return _VisibleArm64
        End Get
        Set(value As Boolean)
            _VisibleArm64 = value
            NotifyPropertyChanged("VisibleArm64")
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
    Public Property SelectedX86 As System.Nullable(Of Boolean)
        Get
            Return _SelectedX86
        End Get
        Set(value As System.Nullable(Of Boolean))
            If Not VisibleX86 Then
                Return
            End If
            _SelectedX86 = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs(SelectionChangedEventArgs.Reason.SelectedX86))
            NotifyPropertyChanged("SelectedX86")
        End Set
    End Property
    Public Property SelectedX64 As System.Nullable(Of Boolean)
        Get
            Return _SelectedX64
        End Get
        Set(value As System.Nullable(Of Boolean))
            If Not VisibleX64 Then
                Return
            End If
            _SelectedX64 = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs(SelectionChangedEventArgs.Reason.SelectedX64))
            NotifyPropertyChanged("SelectedX64")
        End Set
    End Property
    Public Property SelectedArm64 As System.Nullable(Of Boolean)
        Get
            Return _SelectedArm64
        End Get
        Set(value As System.Nullable(Of Boolean))
            If Not VisibleArm64 Then
                Return
            End If
            _SelectedArm64 = value
            RaiseEvent SelectionChanged(Me, New SelectionChangedEventArgs(SelectionChangedEventArgs.Reason.SelectedArm64))
            NotifyPropertyChanged("SelectedArm64")
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
    Public Property EnabledX86 As Boolean
        Get
            Return _EnabledX86
        End Get
        Set(value As Boolean)
            _EnabledX86 = value
            NotifyPropertyChanged("EnabledX86")
        End Set
    End Property
    Public Property EnabledX64 As Boolean
        Get
            Return _EnabledX64
        End Get
        Set(value As Boolean)
            _EnabledX64 = value
            NotifyPropertyChanged("EnabledX64")
        End Set
    End Property
    Public Property EnabledArm64 As Boolean
        Get
            Return _EnabledArm64
        End Get
        Set(value As Boolean)
            _EnabledArm64 = value
            NotifyPropertyChanged("EnabledArm64")
        End Set
    End Property

    Public SelectionChangedCancelRequest As Boolean = False

End Class
